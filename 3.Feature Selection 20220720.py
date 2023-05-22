# -*- coding: utf-8 -*-
"""
Created on Thu Jul 14 15:48:28 2022 ---- Feature selection

@author: mkong2
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
import statsmodels.api as sm
os.chdir(r'C:\Users\mkong2\OneDrive - KPMG\Documents\2022 Projects\MK Retail Index\Data\Inputs')

#%% read in the data 

data_frames1= pd.read_pickle('data_frames1.pickle')
data_frames1.columns
#%% feature selection --- try backwards elimination
X = data_frames1.drop(["Retail trade",'Date'],1)   #Feature Matrix
y = data_frames1["Retail trade"]          #Target Variable
#Adding constant column of ones, mandatory for sm.OLS model
X_1 = sm.add_constant(X)

#Fitting sm.OLS model
model = sm.OLS(y,X_1).fit()
model.pvalues
#%%
#Backward Elimination
cols = list(X.columns)
pmax = 1
while (len(cols)>0):
    p= []
    X_1 = X[cols]
    X_1 = sm.add_constant(X_1)
    model = sm.OLS(y,X_1).fit()
    p = pd.Series(model.pvalues.values[1:],index = cols)      
    pmax = max(p)
    feature_with_p_max = p.idxmax()
    if(pmax>0.05):
        cols.remove(feature_with_p_max)
    else:
        break
selected_features_BE = cols
print(selected_features_BE)

