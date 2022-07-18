library(tidyverse)
library(lubridate)
library(ggrepel)
library(RColorBrewer)
setwd("D:/Estelle/python/cb_rate_hike")


country_codes <- 
  read_csv("country_code_rates.csv") %>% 
  left_join(read_csv("country_code_implied_rates.csv"), by = "country_full_name") %>% 
  rename(actual_rate = '...1.x', 
         implied_rate = '...1.y') %>% 
  filter(actual_rate != "KLIB3M Index"| actual_rate != "JIBA3M Index" | actual_rate != "WIBR3M Index") 

#cleaning data pulled from Bloomberg
current_cb_rates <- 
  read_csv("output_actual.csv") %>% 
  select(-`KLIB3M Index`, -`JIBA3M Index`, -`WIBR3M Index`) %>%
  filter(!is.na(`...1`)) %>% 
  rename(date = `...1`) %>% 
  pivot_longer(-date) %>% 
  group_by(name) %>% 
  fill(value, .direction = "down") %>% 
  ungroup() 

one_yr_foward_implied <-   
  read_csv("output_implied_rates.csv") %>% 
  filter(!is.na(`...1`)) %>% 
  rename(date = `...1`) %>% 
  pivot_longer(-date) %>% 
  mutate(value = as.double(value),
         value = round(value,1)) %>% 
  filter(date == last(date))

#creating dataset of pre-covid rates
pre_covid_rates <-
  current_cb_rates %>% 
  filter(date < as.Date("2020-12-30"),
         !is.na(value))%>% 
  group_by(name) %>% 
  distinct(value) %>% 
  filter(value == min(value)) %>% 
  ungroup() %>% 
  rename( pre_covid=value, 
          actual_rate = name) %>% 
  left_join(country_codes) %>% 
  select(country_full_name, pre_covid) %>% 
  filter(!is.na(country_full_name))

#creating dataset of current rates

current_rate <- 
  current_cb_rates %>% 
  filter(date == last(date)) %>% 
  rename(current = value, 
         actual_rate = name) %>% 
  ungroup() %>% 
  left_join(country_codes) %>% 
  select(country_full_name, current) %>% 
  filter(!is.na(country_full_name))

one_yr_implied <- 
  one_yr_foward_implied %>% 
  filter(date == last(date)) %>% 
  rename(one_yr_implied = value, 
         implied_rate = name) %>% 
  ungroup() %>% 
  left_join(country_codes) %>% 
  select(country_full_name, one_yr_implied)

#putting the full dataset together
data <- 
  pre_covid_rates %>% 
  left_join(current_rate) %>% 
  left_join(one_yr_implied) %>% 
  unique() %>% 
  mutate(pre_covid = as.double(pre_covid),
         current = as.double(current)) %>% 
  filter(!is.na(one_yr_implied), 
         !is.na(pre_covid)) %>% 
  pivot_longer(-country_full_name) %>% 
  mutate(name = ifelse(name == "pre_covid", "Covid-low", 
                       ifelse(name == "current", "Current", "One-Year Forward Market Implied Rate"))) %>% 
  mutate(name = factor(name, levels = c("Covid-low", "Current", "One-Year Forward Market Implied Rate"))) %>% 
  filter(
         #  country_full_name != "TURKEY",
         # country_full_name != "BRAZIL",
         country_full_name != "EUROZONE",
         country_full_name != "CANADA",
         country_full_name != "NORWAY",
         country_full_name != "TAIWAN",
         country_full_name != "PHILIPPINES",
         country_full_name != "AUSTRALIA",
         country_full_name != "NEW ZEALAND",
         country_full_name != "BRITAIN",
         country_full_name != "SWEDEN",
         country_full_name != "SWITZERLAND",
         country_full_name != "UNITED STATES")

hiked_reference_data <-
  pre_covid_rates %>% 
  left_join(current_rate) %>% 
  left_join(one_yr_implied) %>% 
  unique() %>% 
  mutate(pre_covid = as.double(pre_covid),
         current = as.double(current)) %>% 
  filter(!is.na(one_yr_implied), 
         !is.na(pre_covid))  %>% 
  mutate(hiked = current - pre_covid) %>% 
  select(country_full_name, hiked)

hiked_dataset <- 
  data %>% 
  left_join(hiked_reference_data) %>% 
  filter(hiked > 0) %>% 
  select(-hiked)

not_hiked <- 
  data %>% 
  left_join(hiked_reference_data) %>% 
  filter(hiked <= 0) %>% 
  select(-hiked)

future_hikes <- 
  data %>% 
  filter(name != "Covid-low") 

#for charting labeling purposes, manually creating a list of country names that
#should be on the left and right hand side of the graph
left <- 
  c( "INDIA","THAILAND",
    "MALAYSIA", "TURKEY", "CZECH","HUNGARY", "SOUTH AFRICA", "TAIWAN")

  
right <- 
 c( "RUSSIA","ROMANIA","CHILE", "BRAZIL", "POLAND", "MEXICO", "SOUTH KOREA", "COLOMBIA")


getPalette = colorRampPalette(brewer.pal(9, "Set1"))


#past present future chart
  ggplot() +
  geom_point(data = data, 
             aes(x=name, y = value, color = country_full_name, group = country_full_name),
             size = 3)+
  geom_vline(xintercept=which(data$name == 'Covid-low'), linetype = 2) +
  geom_vline(xintercept=which(data$name == 'Current'), linetype = 2) +
  geom_vline(xintercept=which(data$name == 'One-Year Forward Market Implied Rate'), linetype = 2) +
  geom_line(data = 
              hiked_dataset %>% 
              filter(name != "One-Year Forward Market Implied Rate"),
             aes(x=name, y = value, color = country_full_name, group = country_full_name), 
                linetype = 2)+
  geom_line(data = 
              not_hiked %>% 
              filter(name != "One-Year Forward Market Implied Rate"),
            aes(x=name, y = value, color = country_full_name, group = country_full_name), 
            linetype = 1, size = 1.5)+
  geom_line(data = 
              data %>% 
              filter(name != "Covid-low"),
            aes(x=name, y = value, color =country_full_name, group = country_full_name), 
              linetype = 1, size = 0.5 )+ 
  geom_text_repel(data =
                  data%>%
                  filter(country_full_name %in% right) %>%
                  filter(name == "One-Year Forward Market Implied Rate"),
             aes(x=name, y = value,
                 label = country_full_name,
                 color = country_full_name,
                 group = country_full_name),
            show.legend = FALSE,
            hjust = -3,
            size = 3,
            fontface = "bold") +
    geom_text_repel(data =
                      data%>%
                      filter(country_full_name %in% left) %>%
                      filter(name == "Covid-low"),
                    aes(x=name, y = value,
                        label = country_full_name,
                        color = country_full_name,
                        group = country_full_name),
                    position = position_dodge2(0.1),
                    show.legend = FALSE,
                    # vjust = 1,
                    hjust =2,
                    size = 3,
                    fontface = "bold") +
    labs(title = "Divergent EM Central Banking (as of 2021-11-05)", 
         subtitle = "Key Policy Rate (%)",
         x = "", y = "",
         caption = "Source: Bloomberg")+
    annotate("text", x = data$name[1], y = 9, label = "Central banks that have \nnot hiked rates (bolded line)",
             hjust = -0.1, 
             size = 3, 
             fontface = "italic") +
    annotate("text", x = data$name[2], y = 14.5, label = "   Upward sloping solid line:\n   rate hike expected within next year",
             hjust = 0.0001, 
             size = 3, 
             fontface = "italic")+
    scale_color_manual(values = getPalette(15))+
    estelle_theme() +
    theme(legend.position = "none", 
          plot.title = element_text(color = "black", size = 12),
          plot.caption = element_text(size = 11, margin = margin (-0.5, 0, 0, 0, "cm")),
          plot.margin = margin(1, 1, 0.5, 0.5, "cm"),
          plot.subtitle = element_text(size = 11, margin = margin (0, 0, 0, 0, "cm")),
          axis.text = element_text(size = 11, face = "bold"))
  
ggsave("cb_rate_not_hiked.png")

