#### This script is to 
from statsmodels.tsa.statespace.varmax import VARMAX
from statsmodels.tsa.api import VAR
from statsmodels.tsa.stattools import grangercausalitytests, adfuller
import matplotlib.pyplot as plt
import statsmodels.api as sm
import pandas as pd
import numpy as np
import os

# Read the master data from the step of "VAR model" ---"\\ausydfsr11\_tax\Tax Technology & Innovation\Digital Solutions\Deal Advisory\Retail Index\Code\2022 May\scripts\VAR model - MK - AR.py"

os.chdir(r'C:\Users\mkong2\OneDrive - KPMG\Documents\2022 Projects\MK Retail Index\Data\Inputs')
#%%
master_data1 = pd.read_pickle('master_data1.pickle')
master_data1.tail()

master_data2 = master_data1[:'Dec 2021']
master_data2.tail()
#%%
master_data2.columns
#%% building VAR model

###########################based on the causality check, i now compose a new dataset for VAR model
############################ we only pick those with causality relationship ######################
###### this is from feature selection
master_data2.columns
VAR_data = master_data2[[ 'Retail trade','raw_loans_liability', 'raw_cost_wage_manu', 'raw_saving_personal_sector', 'raw_participate', 'raw_house_price']]
VAR_data.shape
VAR_data.tail()
#%% buiding the model  + select the order 
##VAR_data['raw_IR'].iloc[-1]=VAR_data['raw_IR'].iloc[-1]+0.5

### select order 
##### take the 1st difference between 

model = VAR(VAR_data.diff()[1:].astype(float))


sorted_order=model.select_order(maxlags=None, trend='ct')
print(sorted_order.summary())
#%%
### select  or 4???
### in VAR model, we do not have to take the first diff to enable the model specification ######################

var_model = VARMAX(VAR_data.astype(float), order=(4,0),enforce_stationarity= True)
fitted_model = var_model.fit(disp=False)
fitted_model.summary()
#%%
####### pick coefficients with P <0.05 as the significant ones.

n_forecast = 12
predict = fitted_model.get_prediction(start=len(VAR_data),end=len(VAR_data) + n_forecast-1)#start="1989-07-01",end='1999-01-01')

predictions=predict.predicted_mean
##predictions.columns=['ulc_predicted','rgnp_predicted']

predictions.index=predictions.index.strftime('%b %Y')



# Getting the Dates for test dataset for visualization


####COMBINE REAL AND forecast dataset -----

all_data = pd.concat([VAR_data,predictions]).reset_index()
all_data.to_csv('all_data_20220720.csv')


###my code stoped here, as we will impose 100 as the base for DEC 21.





 