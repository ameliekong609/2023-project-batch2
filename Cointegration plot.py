
###### time series diagnosis ############################################################
## Ming Kong
##May 2022

#############step 1 check the time sereis  ######
# plot the 2 time series ######
import pandas as pd
import numpy as np
import re
from functools import reduce
import matplotlib.pyplot as plt
import os

os.chdir(r'C:\Users\mkong2\OneDrive - KPMG\Documents\2022 Projects\MK Retail Index\Scripts')

### read data
raw_CPI_grow_clean = pd.read_pickle('raw_CPI_grow_clean.pkl')
raw_retail_index2 = pd.read_pickle('raw_retail_index2.pkl')
raw_GDP_grow_clean=pd.read_pickle('raw_GDP_grow_clean.pkl')
raw_UNEMPLOYMENT_clean =pd.read_pickle('raw_UNEMPLOYMENT_clean.pkl')
raw_saving_personal_sector_clean=pd.read_pickle('raw_saving_personal_sector_clean.pkl')

dataset =[raw_CPI_grow_clean, raw_GDP_grow_clean, raw_UNEMPLOYMENT_clean,raw_saving_personal_sector_clean ]
names=['raw_CPI_grow','raw_GDP_grow','raw_UNEMPLOYMENT','raw_saving_personal_sector']

#######plot time series  between Retail and other variables 

for i in range(0,len(dataset)):
    data_temp= dataset[i]
    dataframe=pd.concat([raw_retail_index2,data_temp],axis=1, join ='inner').iloc[:,:-1]

    fig, ax_left = plt.subplots()
    ax_left.plot(dataframe['Date'],dataframe[names[i]], color='blue',label=names[i])
#ax_left.set_ylabel("CPI",color="blue",fontsize=14)
    ax_right = ax_left.twinx()
    ax_right.plot(dataframe['Date'],dataframe['Retail trade'], color='red',label='Retail Trade')
#ax_right.set_ylabel("Retail",color="red",fontsize=14)
# adding Label to the x-axis
    ax_left.legend(loc=0)
    plt.legend()
    plt.xticks(['Dec 2001','Dec 2005','Dec 2010','Dec 2015','Dec 2020'])
    plt.savefig(names[i]+".png")
    i+=1
    #plt.show()
    plt.close()


