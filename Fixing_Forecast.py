##### This code is for Sector Intelligence Forecast ###############################

import numpy as np
import pandas as pd
import math
from sklearn import linear_model
import statsmodels.api as sm
import datetime as dt
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.tsa.seasonal import seasonal_decompose
from dateutil.parser import parse
import warnings
import itertools
from pylab import rcParams
import os
from datetime import date
from statsmodels.tsa.stattools import adfuller, acf, pacf
from statsmodels.tsa.arima.model import ARIMA 
from dfply import *

### read raw data  #########################################
secData = pd.read_csv(r'\\ausydfsr11\_tax\Tax Technology & Innovation\Digital Solutions\Deal Advisory\Sector Intelligence\Sep 2021 Update\2. Data\March update\Returns and Volatility_secIdxd_10.05.2022_trading_day_updated.csv')

#### only looking at AU data  #################################
secData_au = secData[secData['Country']=='Australia']
print(secData_au.groupby('Sector').size())
print(secData_au.shape) ### good size up from 24606 to 24822
secData_au.head()


### reshape the table from long to wide  #############################
secData_au_price1 = pd.DataFrame(secData_au.pivot(index=['Date', 'Year', 'Month', 'Day', 'Trading_Day_Ind', 'Yearly_Indicator', 'Quarterly_Indicator', 'Monthly_Indicator', 'Country', 'Frequency'], 
                                    columns='Sector', values='Sector_Index_Value'))

secData_au_price2 = secData_au_price1.reset_index()
secData_au_price2.columns
secData_au_price2.tail()
secData_au_price2[secData_au_price2['Trading_Day_Ind']=='Yes']

###################
secData_au_price2 =secData_au_price2.drop(columns=['Frequency'])
secData_au_price2.columns
secData_au_price2.shape

########################################3 this is to further tidy up the data################################

secData_au_price2.columns = secData_au_price2.columns.str.replace(' ','_')
secData_au_price2.columns = secData_au_price2.columns.str.replace('S&P/','')  ## this is to remove "S&P" prefix
secData_au_price2.columns


###################### 

## What does the monthly data looks like? 
# -- Better use average daily results for the month

secData_au_price3 = (secData_au_price2 >>
                     filter_by(X.Trading_Day_Ind == 'Yes') >>
                     drop(X.Date, X.Day, X.Trading_Day_Ind, X.Yearly_Indicator, X.Quarterly_Indicator, X.Monthly_Indicator) >>
                     group_by(X.Year, X.Month, X.Country) >>
                     summarise(Communications_Services = X.Communications_Services.mean(),
                               Consumer_Discretionary = X.Consumer_Discretionary.mean(), 
                               Consumer_Staples = X.Consumer_Staples.mean(),
                               Energy = X.Energy.mean(), 
                               Financials = X.Financials.mean(), 
                               Health_Care = X.Health_Care.mean(), 
                               Industrials = X.Industrials.mean(),
                               Information_Technology = X.Information_Technology.mean(), 
                               Materials = X.Materials.mean(), 
                               Real_Estate = X.Real_Estate.mean(),
                               ASX_All_Ordinaries_Index = X.ASX_All_Ordinaries_Index.mean(), 
                               Utilities = X.Utilities.mean()
                               ) >>
                     mutate(Date = pd.Series(secData_au_price2['Date'][secData_au_price2['Monthly_Indicator']=='Yes'].index)))



secData_au_price3.tail()
#######################################

secData_au_price3.set_index(pd.date_range(start='2011-01-01', end='2022-03-31', freq='M'), inplace=True)
secData_au_price3.index
secData_au_price3.head()



##########################plot 

secData_au_price3.drop(['Year', 'Month', 'Date'], axis=1).plot(figsize=(15, 6))
plt.show()

# write to csv
secData_au_price3.to_csv('TPA_monthly data_secData_au_price3_20220530.csv')




###########################################################################################
##### Forecasting with SARIMA
### A univariate time series forecasting on monthly SI data
###########################################################################################

sector_List = pd.Series(secData_au['Sector'].unique(),name='Sector').str.replace(' ','_')
sector_List.replace('S&P/ASX_All_Ordinaries_Index', 'ASX_All_Ordinaries_Index', inplace=True)
sector_List2=pd.DataFrame(sector_List)
##set_index(pd.date_range(start=0, end=11, freq=1), inplace=True)
sector_List2['Index']=np.arange(len(sector_List2))
sector_List2