library(tidyverse)
library(lubridate)
library(ggrepel)
library(RColorBrewer)
setwd("D:/Estelle/python/cb_rate_hike")


country_codes <- 
  read_csv("country_code_rates.csv") %>% 
  # left_join(read_csv("country_code_implied_rates.csv"), by = "country_full_name") %>% 
  rename(actual_rate = '...1') %>% 
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


#putting the full dataset together
data <- 
  pre_covid_rates %>% 
  left_join(current_rate) %>% 
  unique() %>% 
  mutate(pre_covid = as.double(pre_covid),
         current = as.double(current)) %>% 
  filter(!is.na(pre_covid)) %>% 
  pivot_longer(-country_full_name) %>% 
  mutate(name = ifelse(name == "pre_covid", "Pre-Covid",  "Current")) %>% 
  mutate(name = factor(name, levels = c("Pre-Covid", "Current"))) %>% 
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
  unique() %>% 
  mutate(pre_covid = as.double(pre_covid),
         current = as.double(current)) %>% 
  filter(!is.na(pre_covid))  %>% 
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
  filter(name != "Pre-Covid") 

#for charting labeling purposes, manually creating a list of country names that
#should be on the left and right hand side of the graph
left <- 
  c("RUSSIA","CHILE", 
    "BRAZIL", "TURKEY", "CZECH","HUNGARY", "SOUTH AFRICA")


right <- 
  c( "INDIA", "THAILAND","ROMANIA",
     "UNITED STATES", "MALAYSIA", "POLAND", "MEXICO", "SOUTH KOREA", "COLOMBIA")


getPalette = colorRampPalette(brewer.pal(9, "Set1"))


#past present future chart
ggplot() +
  geom_point(data = data, 
             aes(x=name, y = value, color = country_full_name, group = country_full_name),
             size = 3)+
  geom_vline(xintercept=which(data$name == 'Pre-Covid'), linetype = 2) +
  geom_vline(xintercept=which(data$name == 'Current'), linetype = 2) +
  geom_line(data = 
              hiked_dataset ,
            aes(x=name, y = value, color = country_full_name, group = country_full_name), 
            linetype = 1, size = 2)+
  geom_line(data = 
              not_hiked,
            aes(x=name, y = value, color = country_full_name, group = country_full_name), 
            linetype = 2)+
  geom_line(data = 
              data %>% 
              filter(name != "Pre-Covid"),
            aes(x=name, y = value, color =country_full_name, group = country_full_name), 
            linetype = 1, size = 0.5 )+ 
  geom_text_repel(data =
                    data%>%
                    filter(country_full_name %in% right) %>%
                    filter(name == "Current"),
                  aes(x=name, y = value,
                      label = country_full_name,
                      color = country_full_name,
                      group = country_full_name),
                  show.legend = FALSE,
                  hjust = -2,
                  size = 3,
                  fontface = "bold") +
  geom_text_repel(data =
                    data%>%
                    filter(country_full_name %in% left) %>%
                    filter(name == "Pre-Covid"),
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
  labs(title = "Select EM Central Bank Policy Paths--Past, Present, Future", 
       subtitle = "Key Policy Rate (%)",
       x = "", y = "",
       caption = "Source: Bloomberg")+
  annotate("text", x = data$name[1], y = 17, label = "Central banks that have hiked rates\n above pre-Covid levels in bold",
           hjust = -0.1, 
           size = 3, 
           fontface = "bold") +
  scale_color_manual(values = getPalette(17))+
  estelle_theme() +
  theme(legend.position = "none", 
        plot.title = element_text(color = "black", size = 12), 
        plot.caption = element_text(size = 11, margin = margin (-0.5, 0, 0, 0, "cm")),
        plot.margin = margin(1, 1, 0.5, 0.5, "cm"),
        plot.subtitle = element_text(size = 11, margin = margin (0, 0, 0, 0, "cm")),
        axis.text = element_text(size = 11, face = "bold"))
