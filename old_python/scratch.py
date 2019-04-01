# -*- coding: utf-8 -*-
"""
Created on Thu Dec 21 15:24:43 2017

@author: u4473753
"""

import pandas as pd



sample_tracking= pd.ExcelFile("/data/temp/IWYP60_EUE_Draft_Sample_Tracking_20171220_DC.xlsx")


#Sample;tissue
#Sample;stage

tissues = list()
stages = list()
sample_types = list()



sample_tracking_accession = sample_tracking.parse("Sample")

for accrow in sample_tracking_accession.itertuples(index=True, name='Sample'):
    
    if not (pd.isnull(getattr(accrow, "Tissue"))):
        if not getattr(accrow, "Tissue") in tissues:
            tissues.append(getattr(accrow, "Tissue"))
        else:
            print tissues.index(getattr(accrow, "Tissue"))
    
    if not (pd.isnull(getattr(accrow, "Stage"))):
        if not getattr(accrow, "Stage") in stages:
            stages.append(getattr(accrow, "Stage"))
        else:
            print stages.index(getattr(accrow, "Stage"))

    
    #NB: Because there is a space in "Sample Name", pd won't parse it. It is "_9"
    if not (pd.isnull(getattr(accrow, "_9"))):
        if not getattr(accrow, "_9") in sample_types:
            sample_types.append(getattr(accrow, "_9"))
        else:
            print sample_types.index(getattr(accrow, "_9"))


    
tissues.sort
stages.sort
sample_types.sort


print(tissues,len(tissues))
print(stages, len(stages))
print(sample_types,(sample_types))