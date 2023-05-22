# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
#%% import libraries and os
import pandas as pd
import numpy as np
import re
from functools import reduce
import matplotlib.pyplot as plt
import os
import itertools
from scipy.stats.stats import pearsonr
import seaborn as sns
os.chdir(r'C:\Users\mkong2\OneDrive - KPMG\Documents\2022 Projects\MK Retail Index\Data\Inputs')

# %% IMport the data -these data are newly decided as per July 2022 #################################
# Consumer Sentiment Index
raw_BCI = pd.read_csv('Business Confidence Index.csv')
#raw_CSI = pd.read_csv('Consumer Sentiment.csv') ## this data is only available from 2007
raw_CSI = pd.read_csv('Customer Confidence Index.csv')
raw_WT = pd.read_csv('Oxecon WT- 6 May 2022 15_14_08.csv')
raw_loans_liability = pd.read_csv('Oxecon Loans_liabilities_household - 6 May 2022 15_09_40.csv')
raw_financial_liability = pd.read_csv('Oxecon Financial_liability- 6 May 2022 15_07_30.csv')   ### should be better
raw_cost_wage_manu = pd.read_csv('Oxecon Costs_unit_wage - 6 May 2022 15_05_35.csv')
raw_saving_personal_sector = pd.read_csv('Oxecon Savings_personal_sector - 6 May 2022 15_13_21.csv')
raw_participate = pd.read_csv('Oxecon participate - 6 May 2022 15_10_25.csv')
raw_house_price = pd.read_csv('C:\\Users\\mkong2\\OneDrive - KPMG\\Documents\\2022 Projects\\MK Retail Index\\Data\\Oxford\\Level2\\Oxecon House_price- 6 May 2022 15_08_45.csv')

#%% this is the dependent variable
raw_retail_index = pd.read_excel('5206006_Industry_GVA_20220714.xlsx',sheet_name='Data1')
raw_retail_index1=raw_retail_index.loc[10:,["Unnamed: 0","Retail trade (G) ;.1"]].reset_index(drop=True)
raw_retail_index1.columns=['Date','Retail trade']
raw_retail_index1['Date']=pd.to_datetime(raw_retail_index1['Date']).dt.strftime('%b %Y')
raw_retail_index2=raw_retail_index1.loc[(pd.to_datetime(raw_retail_index1['Date']) > (pd.to_datetime('01/01/2001',dayfirst=True))) & (pd.to_datetime(raw_retail_index1['Date']) < (pd.to_datetime('01/01/2022',dayfirst=True)))].reset_index(drop=True)

#%% Clean the data

datasets =[raw_WT,raw_loans_liability,raw_financial_liability,raw_cost_wage_manu,raw_saving_personal_sector,raw_participate,raw_house_price]
names =['raw_WT','raw_loans_liability','raw_financial_liability','raw_cost_wage_manu','raw_saving_personal_sector','raw_participate','raw_house_price']

for i in range(0,len(datasets)) :
    temp = datasets[i]
    temp1 = temp.T.loc['2001':'2021',]    ## transpose data  and ending at  2021
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
    
#%%  clean the data of raw_BCI and raw_CSI
raw_BCI1= raw_BCI[['TIME', 'Value']]
raw_BCI1['Date']= pd.to_datetime(raw_BCI1['TIME']).dt.strftime('%b %Y')
raw_BCI_clean= raw_BCI1.drop(['TIME'],axis=1) 
raw_BCI_clean.columns=['BCI','Date']
raw_BCI_clean=raw_BCI_clean[['Date','BCI']]

raw_CSI1= raw_CSI[['TIME', 'Value']]
raw_CSI1['Date']= pd.to_datetime(raw_CSI1['TIME']).dt.strftime('%b %Y')
raw_CSI_clean= raw_CSI1.drop(['TIME'],axis=1) 
raw_CSI_clean.columns=['CSI','Date']
raw_CSI_clean=raw_CSI_clean[['Date','CSI']]

#%%
raw_WT_clean['raw_WT']=raw_WT_clean['raw_WT'].astype(float)
raw_loans_liability_clean['raw_loans_liability']=raw_loans_liability_clean['raw_loans_liability'].astype(float)
raw_financial_liability_clean['raw_financial_liability']=raw_financial_liability_clean['raw_financial_liability'].astype(float)
raw_cost_wage_manu_clean['raw_cost_wage_manu']=raw_cost_wage_manu_clean['raw_cost_wage_manu'].astype(float)
raw_saving_personal_sector_clean['raw_saving_personal_sector']=raw_saving_personal_sector_clean['raw_saving_personal_sector'].astype(float)
raw_participate_clean['raw_participate']=raw_participate_clean['raw_participate'].astype(float)
raw_retail_index2['Retail trade']=raw_retail_index2['Retail trade'].astype(float)
raw_house_price_clean['raw_house_price']=raw_house_price_clean['raw_house_price'].astype(float)

#%% Calculate the correlation
data_frames = [raw_BCI_clean,
               raw_CSI_clean,
               raw_WT_clean,
               raw_loans_liability_clean,
               raw_financial_liability_clean,
               raw_cost_wage_manu_clean,
               raw_saving_personal_sector_clean,
               raw_participate_clean,
               raw_house_price_clean,
               raw_retail_index2
               ]

data_frames1 = reduce(lambda  left,right: pd.merge(left,right,on=['Date'], how='outer'), data_frames).dropna()     


#%% check the data types
data_frames1.dtypes

data_frames_corr = data_frames1.drop(['Date'],axis=1)
#%%
data_frames_corr.columns
#%% correaltion 
g=sns.pairplot(data_frames_corr)

#%% this is only to see the relationship between x AND y
g=sns.lmplot(x="raw_house_price",y="Retail trade",data=data_frames_corr)

#%%
#Using Pearson Correlation
plt.figure(figsize=(12,10))
cor = data_frames_corr.corr()
sns.heatmap(cor, annot=True, cmap=plt.cm.Reds)
plt.show()


#%% saving to Pickles
raw_BCI_clean.to_pickle('raw_BCI_clean.pickle')
raw_CSI_clean.to_pickle('raw_CSI_clean.pickle')
raw_WT_clean.to_pickle('raw_WT_clean.pickle')
raw_loans_liability_clean.to_pickle('raw_loans_liability_clean.pickle')
raw_financial_liability_clean.to_pickle('raw_financial_liability_clean.pickle')
raw_cost_wage_manu_clean.to_pickle('raw_cost_wage_manu_clean.pickle')
raw_saving_personal_sector_clean.to_pickle('raw_saving_personal_sector_clean.pickle')
raw_participate_clean.to_pickle('raw_participate_clean.pickle')
raw_house_price_clean.to_pickle('raw_house_price_clean.pickle')
raw_retail_index2.to_pickle('raw_retail_index2.pickle')

data_frames1.to_pickle('data_frames1.pickle')
         





