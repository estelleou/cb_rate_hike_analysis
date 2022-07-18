from xbbg import blp 
import blpapi
import pandas
from datetime import date


one_yr_forward_pulls = ['S0042FC 1Y1D BCAL Curncy', 'S0147FC 1Y1D BCAL Curncy', 'S0083FC 1Y1D BCAL Curncy',
                        'S0193FC 1Y1D BCAL Curncy', 'S0089FC 1Y1D BCAL Curncy', 'S0133FC 1Y1D BCAL Curncy',
                        'S0141FC 1Y1D BCAL Curncy', 'S0254FC 1Y1D BCAL Curncy', 'S0312FC 1Y1D BCAL Curncy',
                        'S0319FC 1Y1D BCAL Curncy', 'S0322FC 1Y1D BCAL Curncy', 'S0159FC 1Y1D BCAL Curncy',
                        'S0198FC 1Y1D BCAL Curncy', 'S0046FC 1Y1D BCAL Curncy', 'S0057FC 1Y1D BCAL Curncy',
                        'S0225FC 1Y1D BCAL Curncy', 'S0324FC 1Y1D BCAL Curncy', 'S0018FC 1Y1D BCAL Curncy',
                        'S0179FC 1Y1D BCAL Curncy', 'S0329FC 1Y1D BCAL Curncy', 'S0039FC 1Y1D BCAL Curncy', 
                        'S0164FC 1Y1D BCAL Curncy', 'S0041FC 1Y1D BCAL Curncy', 'S0081FC 1Y1D BCAL Curncy',
                        'S0172FC 1Y1D BCAL Curncy', 'S0020FC 1Y1D BCAL Curncy']

 actual_rate_pull = ['MAOPRATE Index', 'BTRR1DAY Index', 'MXONBR Index', 'PRRRONUS Index', 'IDBIRRPO Index', 
                     'SARPRT Index', 'NZOCR Index', 'SWRRATEI Index', 'KORP7DR Index',  'RBATCTR Index', #                     'INRPYLDP Index', 'POREANN Index', 'CABROVER Index', 'BZSTSETA Index',  'CHOVCHOV Index',
                     'FDTR Index', 'SZLTDEP Index', 'NOBRDEPA Index', 'UKBRBASE Index', 'EURR002W Index',
                     'RREFKANN Index', 'BUBOR03M Index', 'BUBR3M Index', 'PRIB03M Index', 'TDSF90D Index',
                     'PREF3MO Index', 'BZELICA Index', 'COOVIBR Index', 'MOSKP3 Index', 
                      'TRLIB3M Index', 'WIBR3M Index', 'INOOO/N Index']


def get_data():
    benchmark_data = blp.bdh(tickers= one_yr_forward_pulls,
                             flds=['PX_Last'],
                             start_date = '2020-01-01', 
                             end_date = date.today())
    print(benchmark_data)
    data = pandas.DataFrame(benchmark_data)
    return pandas.DataFrame(data).to_csv(r'D:\Estelle\python\cb_rate_hike\output_implied_rates.csv', index=[0])


get_data()

 def get_rates():
     rates_data = blp.bdh(tickers= actual_rate_pull,
                              flds=['PX_Last'],
                              start_date = '2020-01-01', 
                              end_date = date.today())
     print(rates_data)
     r_data = pandas.DataFrame(rates_data)
     return pandas.DataFrame(r_data).to_csv(r'D:\Estelle\python\cb_rate_hike\output_actual.csv', index=[0])

 get_rates()

def get_country():
    benchmark_data = blp.bdp(tickers=one_yr_forward_pulls,
                             flds='COUNTRY_FULL_NAME')
    print(benchmark_data)
    data = pandas.DataFrame(benchmark_data)
    return pandas.DataFrame(data).to_csv(r'D:\Estelle\python\cb_rate_hike\country_code_implied_rates.csv', index=[0])

get_country()

 def get_rates_country():
     rates_country = blp.bdp(tickers=actual_rate_pull,
                              flds='COUNTRY_FULL_NAME')
     print(rates_country)
     r_cntry_data = pandas.DataFrame(rates_country)
     return pandas.DataFrame(r_cntry_data).to_csv(r'D:\Estelle\python\cb_rate_hike\country_code_rates.csv', index=[0])

 get_rates_country()
