### this is to apply VAR model 
# MING KONG
#May 2022

from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.statespace.varmax import VARMAX
from statsmodels.tsa.api import VAR
from statsmodels.tsa.stattools import grangercausalitytests, adfuller
from tqdm import tqdm_notebook
from itertools import product

import matplotlib.pyplot as plt
import statsmodels.api as sm
import pandas as pd
import numpy as np
import os
import warnings
from functools import reduce
warnings.filterwarnings('ignore')
# improt data

os.chdir(r'C:\Users\mkong2\OneDrive - KPMG\Documents\2022 Projects\MK Retail Index\Scripts')

### read data
raw_CPI_grow_clean = pd.read_pickle('raw_CPI_grow_clean.pkl')
raw_retail_index2 = pd.read_pickle('raw_retail_index2.pkl')
raw_GDP_grow_clean=pd.read_pickle('raw_GDP_grow_clean.pkl')
raw_UNEMPLOYMENT_clean =pd.read_pickle('raw_UNEMPLOYMENT_clean.pkl')
raw_saving_personal_sector_clean=pd.read_pickle('raw_saving_personal_sector_clean.pkl')

raw_IR_clean=pd.read_pickle('raw_IR_clean.pkl')
raw_cost_wage_manu_clean=pd.read_pickle('raw_cost_wage_manu_clean.pkl')
raw_financial_liability_clean=pd.read_pickle('raw_financial_liability_clean.pkl')
raw_house_price_clean=pd.read_pickle('raw_house_price_clean.pkl')
raw_loans_liability_clean=pd.read_pickle('raw_loans_liability_clean.pkl')
raw_participate_clean=pd.read_pickle('raw_participate_clean.pkl')
raw_population_clean=pd.read_pickle('raw_population_clean.pkl')

master_data =  [raw_retail_index2,raw_CPI_grow_clean,raw_GDP_grow_clean,raw_UNEMPLOYMENT_clean,raw_saving_personal_sector_clean,raw_IR_clean,raw_cost_wage_manu_clean,
raw_financial_liability_clean,raw_house_price_clean,raw_loans_liability_clean,raw_participate_clean,raw_population_clean] 

master_data1 = reduce(lambda  left,right: pd.merge(left,right,on=['Date'], how='outer'), master_data).dropna() 
master_data1=master_data1.set_index('Date')
master_data1.shape

## plot to see######################################################

fig, axes = plt.subplots(nrows=4, ncols=3, dpi=120, figsize=(10,6))
for i, ax in enumerate(axes.flatten()):
    data = master_data1[master_data1.columns[i]]
    ax.plot(data, color='blue', linewidth=1)
    # Decorations
    ax.set_title(master_data1.columns[i])
    ax.xaxis.set_ticks_position('none')
    ax.yaxis.set_ticks_position('none')
    ax.spines["top"].set_alpha(0)
    ax.tick_params(labelsize=6)

plt.tight_layout()
plt.show()

#### ADF test ###############################################
def ad_test(dataset):
    dftest = adfuller(dataset, autolag = 'AIC',regression='ct')
    print(pd.DataFrame(dataset).columns)
    print("1. ADF : ",dftest[0])
    print("2. P-Value : ", dftest[1])
    print("3. Num Of Lags : ", dftest[2])
    print("4. Num Of Observations Used For ADF Regression:",      dftest[3])
    print("5. Critical Values :")
    for key, val in dftest[4].items():
        print("\t",key, ": ", val)
    if dftest[0] < dftest[4]["5%"]:
        print ("Reject Ho - Time Series is Stationary")
    else:
        print ("Failed to Reject Ho - Time Series is Non-Stationary")    

# --all all
for column in master_data1:
    print(ad_test(master_data1[column].fillna(0)))



###################################Causality check ############################################

print("raw_CPI_grow causes 'Retail trade")
print('\n---------------------\n')
granger_1 = grangercausalitytests(master_data1[['Retail trade', 'raw_CPI_grow']], 4)
# p   less than 0.05 --> cpi causes retail index

print("raw_GDP_grow causes 'Retail trade")
print('\n---------------------\n')
granger_2 = grangercausalitytests(master_data1[['Retail trade', 'raw_GDP_grow']], 4)
# p less than 0.05 --> GDP causes retail index


print("raw_UNEMPLOYMENT causes 'Retail trade")
print('\n---------------------\n')
granger_3 = grangercausalitytests(master_data1[['Retail trade', 'raw_UNEMPLOYMENT']], 4)
# p less than 0.05 --> unemployment causes retail index

print("raw_saving_personal_sector causes 'Retail trade")
print('\n---------------------\n')
granger_4 = grangercausalitytests(master_data1[['Retail trade', 'raw_saving_personal_sector']], 4)
# p less than 0.05 --> personal saving causes retail index

print("raw_IR causes 'Retail trade")
print('\n---------------------\n')
granger_5 = grangercausalitytests(master_data1[['Retail trade', 'raw_IR']], 4)
# p greater than 0.05 --> interest rate does not cause retail index

print("raw_cost_wage_manu causes 'Retail trade")
print('\n---------------------\n')
granger_6 = grangercausalitytests(master_data1[['Retail trade', 'raw_cost_wage_manu']], 4)
# p less than 0.05 --> Total labour cost causes retail index


print("raw_financial_liability causes 'Retail trade")
print('\n---------------------\n')
granger_7 = grangercausalitytests(master_data1[['Retail trade', 'raw_financial_liability']], 4)
# p greater than 0.05 --> financial liability does not causes retail index


print("raw_house_price causes 'Retail trade")
print('\n---------------------\n')
granger_8 = grangercausalitytests(master_data1[['Retail trade', 'raw_house_price']], 4)
# p greater than 0.05 --> housing price does not causes retail index


print("raw_loans_liability causes 'Retail trade")
print('\n---------------------\n')
granger_9 = grangercausalitytests(master_data1[['Retail trade', 'raw_loans_liability']], 4)
# p < 0.05, loan causes retail 

print("raw_participate causes 'Retail trade")
print('\n---------------------\n')
granger_10 = grangercausalitytests(master_data1[['Retail trade', 'raw_participate']], 4)
# p<0.05, participation causes retail

print("raw_population causes 'Retail trade")
print('\n---------------------\n')
granger_11 = grangercausalitytests(master_data1[['Retail trade', 'raw_population']], 4)
# p >0.05, population does not cause retail 

###########################based on the causality check, i now compose a new dataset for VAR model 

VAR_data = master_data1[[ 'Retail trade', 'raw_CPI_grow',  'raw_GDP_grow','raw_UNEMPLOYMENT'  , 'raw_saving_personal_sector','raw_cost_wage_manu',  'raw_loans_liability', 'raw_participate' ]]
VAR_data.shape

### select order 
 
model = VAR(VAR_data.diff()[1:].astype(float))

sorted_order=model.select_order(maxlags=None, trend='ct')
print(sorted_order.summary())

### select 8???

var_model = VARMAX(VAR_data.astype(float), order=(4,0),enforce_stationarity= True)
fitted_model = var_model.fit(disp=False)
fitted_model.summary()
