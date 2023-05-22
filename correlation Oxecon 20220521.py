import pandas as pd
import numpy as np
import re
from functools import reduce
import matplotlib.pyplot as plt
import os

###### IMport the data --- LEVEL 1 #################################
raw_CPI_grow = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level1\\Oxecon_Consumer_price_YOY.csv')

raw_GDP_grow = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level1\\Oxecon_GDP_growth.csv')
raw_IR = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level1\\Oxecon_Interest_rate_central_bank_end.csv')
raw_UNEMPLOYMENT = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level1\\Oxecon_unemployment.csv')

#### this is the dependent variable
raw_retail_index = pd.read_excel('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level1\\5206006_Industry_GVA.xlsx',sheet_name='Data1')
raw_retail_index1=raw_retail_index.loc[10:,["Unnamed: 0","Retail trade (G) ;.1"]].reset_index(drop=True)
raw_retail_index1.columns=['Date','Retail trade']
raw_retail_index1['Date']=pd.to_datetime(raw_retail_index1['Date']).dt.strftime('%b %Y')
raw_retail_index2=raw_retail_index1.loc[(pd.to_datetime(raw_retail_index1['Date']) > (pd.to_datetime('01/01/2001',dayfirst=True))) & (pd.to_datetime(raw_retail_index1['Date']) < (pd.to_datetime('01/01/2022',dayfirst=True)))].reset_index(drop=True)
raw_retail_index2

###### IMport the data --- LEVEL 2 #################################
raw_cost_wage_manu = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon Costs_unit_wage - 6 May 2022 15_05_35.csv')
raw_financial_liability = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon Financial_liability- 6 May 2022 15_07_30.csv')
raw_house_price = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon House_price- 6 May 2022 15_08_45.csv')
raw_loans_liability = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon Loans_liabilities_household - 6 May 2022 15_09_40.csv')
raw_participate = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon participate - 6 May 2022 15_10_25.csv')
raw_population = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon population - 6 May 2022 15_12_43.csv')
raw_saving_personal_sector = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon Savings_personal_sector - 6 May 2022 15_13_21.csv')
raw_WT = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon WT- 6 May 2022 15_14_08.csv')

######################### clean the data ########################
##### clean the data on one go 
datasets =[raw_CPI_grow,raw_GDP_grow,raw_IR,raw_UNEMPLOYMENT,raw_cost_wage_manu,raw_financial_liability,raw_house_price,raw_loans_liability,raw_participate,raw_population,raw_saving_personal_sector,raw_WT]
names =['raw_CPI_grow','raw_GDP_grow','raw_IR','raw_UNEMPLOYMENT','raw_cost_wage_manu','raw_financial_liability','raw_house_price','raw_loans_liability','raw_participate','raw_population','raw_saving_personal_sector','raw_WT']

for i in range(0,len(datasets)) :
    temp = datasets[i]
    temp1 = temp.T.loc['2001':'2022',]    ## transpose data 
    temp1.columns =['Q1','Q2','Q3','Q4']   ## add column name
    temp2=temp1.stack().to_frame().reset_index()             ## stack data and release the index
    temp2.columns=['Year','Quarter',names[i]]
    temp2['Date'] = temp2['Quarter'] + " " +temp2['Year']    ## create a new column to match the dependent variable who has data as "Q1 20SS" format
    temp3=temp2.drop(['Year','Quarter'],axis=1)               ## get rid of these unnecessary ones
    temp3['Date']=temp3['Date'].apply(lambda x: x.replace("Q1", "Mar"))
    temp3['Date']=temp3['Date'].apply(lambda x: x.replace("Q2", "Jun"))
    temp3['Date']=temp3['Date'].apply(lambda x: x.replace("Q3", "Sep"))
    temp3['Date']=temp3['Date'].apply(lambda x: x.replace("Q4", "Dec"))
    globals()[names[i]+'_clean']= temp3                       ##create new datasets using name format of "XXXXX_clean"

### now we have 11 new datasets   #############################################
raw_CPI_grow_clean.shape  # this is YOY change of CPI
raw_GDP_grow_clean.shape  # GDP is growth rate
raw_IR_clean.shape   # interest rate  
raw_UNEMPLOYMENT_clean.shape    # unemployment rate
raw_cost_wage_manu_clean.shape       # Costs, unit wage costs, whole economy, nominal
raw_financial_liability_clean.shape        # Financial liabilities, household sector, as a % of disposable income
raw_house_price_clean.shape                       # House price index
raw_loans_liability_clean.shape                   # Loans, liabilities of the household sector, LCU
raw_participate_clean.shape                      # Participation rate
raw_population_clean.shape                        #  Population, total
raw_saving_personal_sector_clean.shape            #  Savings, personal sector ratio


########################## calc the correlation ########################################
##first combine all Y and X var together columnly in ONE dataset
data_frames = [raw_CPI_grow_clean, 
raw_GDP_grow_clean, 
raw_IR_clean, 
raw_UNEMPLOYMENT_clean, 
raw_cost_wage_manu_clean, 
raw_financial_liability_clean,
raw_house_price_clean, 
raw_loans_liability_clean, 
raw_participate_clean, 
raw_population_clean, 
raw_saving_personal_sector_clean,
raw_retail_index2]

data_frames1 = reduce(lambda  left,right: pd.merge(left,right,on=['Date'], how='outer'), data_frames).dropna()    ## retail data only available until Sep 2021

#### second calc the correlation

corr_df = pd.DataFrame()
col_list =[]
cor_list =[]
data=data_frames1.copy()
data = data.drop(columns='Date')
var1 = data['Retail trade'].values
var1=var1.astype(float)

for col in range(len(data.columns)):
    col_list.append(data.columns[col])
    var2 = data.iloc[:,col].values
    var2=var2.astype(float)
    cor = np.corrcoef(var1, var2)
    cor_list.append(cor[0,1])

corr_df['Predictor'] = col_list 
corr_df['Correlation with Retail trade'] = cor_list
corr_df


##################################another way to check the relationship between GDP and Retail index ###################################

from sklearn import   linear_model
# Create linear regression object
regr = linear_model.LinearRegression()

# Train the model using the training sets
Y=data['Retail trade'].values.astype(float)
X=data['raw_GDP'].values.astype(float)
import statsmodels.api as sm
X = sm.add_constant(X)
sm.OLS(Y,X).fit().summary()
