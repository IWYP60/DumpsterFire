# -*- coding: utf-8 -*-
"""
Created on Tue Jul  3 08:38:25 2018

@author: u4473753
"""


import pandas as pd
from sqlalchemy import Column, Integer, String, ForeignKey, Float, and_
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
import logging
import datetime


logging.basicConfig()
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)


#######
##
##
#NB: Issue is found when PANDAS tries to load an excel file that has been saved by LibreOffice
##
##
#######

engine_str = "mysql://iwyp60:<password>@<server>:3306/iwyp60_germinate_dev"



engine = create_engine(engine_str, echo=False, isolation_level="READ UNCOMMITTED")

Base = declarative_base()


createProtsAA = False
createProtsBin = True
createMets = False

loadProtAAData = False
loadProtBinData = True
loadMetData = False




class Experiments(Base):
    __tablename__ = 'experiments'

    id = Column(Integer, primary_key=True)    
    experiment_name = Column(String)
    user_id = Column(String)
    description = Column(String)
    experiment_date = Column(String)
    #experiment_type_id = Column(Integer,ForeignKey("experimenttypes.id"))
    experiment_type_id = Column(Integer)
    created_on = Column(String)
    updated_on = Column(String)

    def __repr__(self):
        return "<Experiments(experiment_name='%s', user_id='%s', description='%s',experiment_date='%s', experiment_type_id='%d', created_on='%s')>" %\
                (self.experiment_name, self.user_id, self.description, self.experiment_date, self.experiment_type_id, self.created_on)



class GerminateBase(Base):
    __tablename__ = 'germinatebase'
    
    id = Column(Integer, primary_key=True)
    general_identifier = Column(String)
    number = Column(String)
    name = Column(String)
    bank_number = Column(String)
    breeders_code = Column(String)
    taxonomy_id = Column(Integer,ForeignKey("taxonomies.id"))
    subtaxa_id = Column(Integer,ForeignKey("subtaxa.id"))
    #NB: While institution_id is a foreign key, this can be updated in the DB later on...
    institution_id = Column(Integer)
    plant_passport = Column(String)
    donor_code = Column(Integer)
    donor_number = Column(String)
    acqdate = Column(String)
    collnumb = Column(String)
    colldate = Column(String)
    collcode = Column(Integer)
    duplsite = Column(String)
    #NB: While biologicalstatus_id is a foreign key, this can be updated in the DB later on...
    biologicalstatus_id = Column(Integer)
    entityparent_id = Column(Integer)
    entitytype_id = Column(Integer)
    collsrc_id = Column(Integer)      
    #NB: While location_id is a foreign key, this can be updated in the DB later on...
    location_id = Column(Integer)
    created_on = Column(String)
    updated_on = Column(String)
    
    
    def __repr__(self):

        return "<GerminateBase(general_identifier='%s', number='%s', name='%s', taxonomy_id='%d', biologicalstatus_id='%d', collsrc_id='%d' notes='%s', self.created_on='%s')>" % \
                (self.general_identifier, self.number, self.name, self.taxonomy_id, self.biologicalstatus_id, self.entityparent_id, self.collsrc_id, self.notes, self.created_on)





#The three types of GCMS/Compound data are: Polypeptide, Functional Protein Bin and Metabolite

#NB: You MUST have sample data present to be able to import the proteomic data

if any([createMets,loadMetData,createProtsAA,createProtsBin,loadProtAAData,loadProtBinData]):

    class Compounds(Base):
        __tablename__ = 'compounds'
    
        id = Column(Integer, primary_key=True)    
        name = Column(String)
        description = Column(String)
        molecular_formula = Column(String)
        monoisotopic_mass = Column(String)
        average_mass = Column(Float)
        compound_class = Column(String)
        #It's probably worth doing this manually. Proteopmic and metabolomic data is in "relative abundance". I believe it is to each other...
        #unit_id = Column(Integer,ForeignKey("units.id"))
        created_on = Column(String)
        updated_on = Column(String)
    
        def __repr__(self):
            return "<Compounds(name='%s', description='%s', molecular_formula='%s', monoisotopic_mass='%g', average_mass='%g', compound_class='%s', created_on='%s')>" %\
                    (self.name, self.description, self.molecular_formula, self.monoisotopic_mass, self.average_mass, self.compound_class, self.created_on)
                    
                    
                    
    class CompoundData(Base):
        __tablename__ = 'compounddata'
                
        id = Column(Integer, primary_key=True)    
        compound_id = Column(Integer,ForeignKey("compounds.id"))
        germinatebase_id = Column(Integer,ForeignKey("germinatebase.id"))
        #dataset_id = Column(String,ForeignKey("dataset.id"))
        #NB: While analysismethod_id is a foreign key, this can be updated in the DB later on...
        analysismethod_id = Column(Integer)
        compound_value = Column(Float)
        recording_date = Column(String)
        created_on = Column(String)
        updated_on = Column(String)
    
        def __repr__(self):
            return "<CompoundData(compound_id='%s', germinatebase_id='%s', analysismethod_id='%s', compound_value='%g', recording_date='%s', created_on='%s')>" %\
                    (self.compound_id, self.germinatebase_id, self.analysismethod_id, self.compound_value, self.recording_date, self.created_on)
                    


Session = sessionmaker(bind=engine)    

connection = engine.connect()

session = Session(bind=connection)



#######
##
##
#NB: You will need to set these parameters at the start so the data imports into the correct location
##
##
#######


#Importing Proteomic and/or Metabolomic information into Germinate

if any([createProtsAA,createProtsBin,loadProtAAData,loadProtBinData]):

    proteomics = pd.ExcelFile("/data/temp/Proteomics_Cimmyt2016_ScaledData_20171012_Copy.xlsx")

    if any([createProtsAA,loadProtAAData]):
        
        polypeptides_parsed = proteomics.parse("ScaledData_Peptide_Level",skiprows=2)
        

        
        for poly in polypeptides_parsed.iterrows():
            
           if createProtsAA:
               #print(poly[1][0])
               existing_protAA_query=session.query(Compounds.id).filter(Compounds.name== poly[1][0])
               existing_protAA_result=session.execute(existing_protAA_query).scalar()

           if not existing_protAA_result:
                   
               polyload = Compounds(name=poly[1][0],description="LCMS polypeptide", compound_class="polypeptide", created_on=datetime.datetime.now())
               session.add(polyload)
               
           if loadProtAAData:
               None
               #print
               
        print ('%d polypeptides added to Germinate') % len(session.new)
        session.commit()
    
    if any([createProtsBin,loadProtBinData]):
        functional_parsed = proteomics.parse("ScaledData_FunctionalBin_Level",skiprows=2)
    
        if createProtsBin:            
            
            for funcbin in functional_parsed.iterrows():

               existing_protbin_query=session.query(Compounds.id).filter(Compounds.name== funcbin[1][0])
               existing_protbin_result=session.execute(existing_protbin_query).scalar()               

               
               if not existing_protbin_result:
                   polyload = Compounds(name=funcbin[1][0],description="LCMS proteomic functional bin (based off one or more polypeptides)", compound_class="proteomic functional bin", created_on=datetime.datetime.now())
                   session.add(polyload)
        
            print ('%d functional proteomic bins added to Germinate') % len(session.new)
            session.commit()
                   
        if loadProtBinData:
               
            for funcbinsample in functional_parsed.columns:
                temp_functbin = None                
                if funcbinsample[:4] != "IW_S":
                    next
                else:
                    temp_functbin = functional_parsed[[functional_parsed.columns[0],funcbinsample]]
                    
                    acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == temp_functbin.columns[1])
                    acc_existing_result=session.execute(acc_existing_query).scalar()
                    
                    for i in range(1,len(temp_functbin)):
                        existing_protbin_query=session.query(Compounds.id).filter(Compounds.name==temp_functbin.iat[i,0].encode('utf-8'))
                        existing_protbin_result=session.execute(existing_protbin_query).scalar()

                        functbinload = CompoundData(compound_id=existing_protbin_result,germinatebase_id=acc_existing_result,compound_value=temp_functbin.iat[i,1])                        
                        session.add(functbinload)

                    
                    #print(temp_functbin)
                    
                    #existing_protbin_query=session.query(Compounds.id).filter(Compounds.name==temp_functbin[0,0])
                    #print(temp_functbin[0][0])
                    
                    #print(temp_functbin.iat[0,0])
                    
                    #functbinload = CompoundData(compound_id)
            session.commit()     
                    
       
#       class CompoundData(Base):
#        __tablename__ = 'compounddata'
#                
#        id = Column(Integer, primary_key=True)    
#        compound_id = Column(Integer,ForeignKey("compounds.id"))
#        germinatebase_id = Column(Integer,ForeignKey("germinatebase.id"))
#        #dataset_id = Column(String,ForeignKey("dataset.id"))
#        #NB: While analysismethod_id is a foreign key, this can be updated in the DB later on...
#        analysismethod_id = Column(Integer)
#        compound_value = Column(Float)
#        recording_date = Column(String)
#        created_on = Column(String)
#        updated_on = Column(String)
#    
#        def __repr__(self):
#            return "<CompoundData(compound_id='%s', germinatebase_id='%s', analysismethod_id='%s', compound_value='%g', recording_date='%s', created_on='%s')>" %\
#                    (self.compound_id, self.germinatebase_id, self.analysismethod_id, self.compound_value, self.recording_date, self.created_on)  
               
               
               
               




if any([createMets,loadMetData]):
    
    #replace this with the relevant metabolomic data file
    metabs = pd.ExcelFile("/data/temp/results_CIMMYT2016_metabolites_20171116RF_scaled(ANU)_Copy.xlsx")


    metabs_parsed = metabs.parse("norm&scaled",skiprows=7)

    for met in metabs_parsed.iterrows():

       if createMets:
           metload = Compounds(name=met[1][0],description="GCMS metabolites", compound_class="metabolite", created_on=datetime.datetime.now())
           session.add(metload)
           
       if loadMetData:
           print

    print ('%d metabolites added to Germinate') % len(session.new)
    session.commit()

