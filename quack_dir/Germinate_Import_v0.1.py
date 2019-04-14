import pandas as pd
from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
#import mysql
import logging
import datetime


logging.basicConfig()
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)



#NB: Issue is found when PANDAS tries to load an excel file that has been saved  by LibreOffice


engine_str = "mysql://iwyp60:<password>@<server>:3306/iwyp60_germinate_dev"


engine = create_engine(engine_str, echo=False, isolation_level="READ UNCOMMITTED")


Base = declarative_base()


class Experiments(Base):
    __tablename__ = 'experiments'

    id = Column(Integer, primary_key=True)
    experiment_number = Column(String)    
    experiment_name = Column(String)
    user_id = Column(String)
    description = Column(String)
    experiment_date = Column(String)
    #experiment_type_id = Column(Integer,ForeignKey("experimenttypes.id"))
    experiment_type_id = Column(Integer)
    created_on = Column(String)
    updated_on = Column(String)

    def __repr__(self):
        return "<Experiments(experiment_number='%s', experiment_name='%s', user_id='%s', description='%s',experiment_date='%s', experiment_type_id='%d', created_on='%s')>" %\
                (self.experiment_number, self.experiment_name, self.user_id, self.description, self.experiment_date, self.experiment_type_id, self.created_on)

class ExperimentDesign(Base):
    __tablename__ = 'experimentdesign'

    id = Column(Integer, primary_key=True)
    name = Column(String)
    plotchamberbench = Column(String)
    row = Column(String)
    column = Column(String)    
    experiments_id = Column(Integer,ForeignKey("experiments.id"))
    notes = Column(String)
    designfile_id = Column(String)
    #experiment_type_id = Column(Integer,ForeignKey("experimenttypes.id"))
    created_on = Column(String)
    updated_on = Column(String)

    def __repr__(self):
        return "<Experiments=Design(name='%s', plotchamberbench='%s', row='%s', column='%s', experiments_id='%s', notes='%s', designfile_id='%s', created_on='%s')>" %\
                (self.name, self.plotchamberbench, self.row, self.column, self.experiments_id, self.notes, self.designfile_id, self.created_on)

class Accession(Base):
    __tablename__ = 'germinatebase'
    
    id = Column(Integer, primary_key=True)
    general_identifier = Column(String)
    number = Column(String)
    name = Column(String)
    bank_number = Column(String)
    breeders_code = Column(String)
    taxonomy_id = Column(Integer,ForeignKey("taxonomies.id"))
    subtaxa_id = Column(Integer,ForeignKey("subtaxa.id"))
    #institution_id = Column(Integer,ForeignKey("institutions.id"))
    institution_id = Column(Integer)
    plant_passport = Column(String)
    donor_code = Column(Integer)
    donor_number = Column(String)
    acqdate = Column(String)
    collnumb = Column(String)
    colldate = Column(String)
    collcode = Column(Integer)
    duplsite = Column(String)
    #biologicalstatus_id = Column(Integer,ForeignKey("biologicalstatus.id"))
    biologicalstatus_id = Column(Integer)
    #collsrc_id = Column(Integer,ForeignKey("collectingsources.id"))
    #location_id = Column(Integer,ForeignKey("locations.id"))
    location_id = Column(Integer)
    notes = Column(String)
    created_on = Column(String)
    updated_on = Column(String)
    
    
    def __repr__(self):
        #return "<Accession(general_identifier='%s', number='%s', name='%s', subtaxa_id='%d', taxonomy_id='%d', institution_id='%d', biologicalstatus_id='%s', location_id='%s', notes='%s', self.created_on='%s')>" % \
                #(self.general_identifier, self.number, self.name, self.subtaxa_id, self.taxonomy_id, self.institution_id, self.biologicalstatus_id, self.location_id, self.notes, self.created_on)

        return "<Accession(general_identifier='%s', number='%s', name='%s', taxonomy_id='%d', biologicalstatus_id='%s', notes='%s', self.created_on='%s')>" % \
                (self.general_identifier, self.number, self.name, self.taxonomy_id, self.biologicalstatus_id, self.notes, self.created_on)


class Locations(Base):
    __tablename__ = 'locations'
    
    id = Column(Integer, primary_key=True)
    site_name = Column(String)
    created_on = Column(String)

    
    def __repr__(self):
        return "<Trial_Series(seriesname='%s'), created_on='%s')>" % (self.seriesname, self.created_on)    
    
    
    
class Trial_Series(Base):
    __tablename__ = 'trialseries'
    
    id = Column(Integer, primary_key=True)
    seriesname = Column(String)
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        return "<Trial_Series(seriesname='%s'), created_on='%s')>" % (self.seriesname, self.created_on)
    
    

class Plant_Plot(Base):
    __tablename__ = 'plantplot' 
    
    id = Column(Integer, primary_key=True)
    number = Column(String)
    name = Column(String)
    germinatebase_id = Column(Integer,ForeignKey("germinatebase.id"))
    locations_id = Column(Integer,ForeignKey("locations.id"))
    experimentdesign_id = Column(Integer,ForeignKey("experimentdesign.id"))
    plantplot_position = Column(String)
    trialseries_id = Column(Integer,ForeignKey("trialseries.id"))
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
#        return "<Plant_Plot(number='%s', name='%s', germinatebase_id='%d', plantplot_position='%s', trialseries_id='%d', created_on='%s')>" % \
#                (self.number, self.name, self.germinatebase_id, self.plantplot_position, self.trialseries_id, self.created_on)
        return "<Plant_Plot(number='%s', name='%s', germinatebase_id='%d', location_id='%d', experimentdesign_id='%d', trialseries_id='%d', plantplot_position='%s', created_on='%s')>" % \
                (self.number, self.name, self.germinatebase_id, self.location_id, self.experimentdesign_id,  self.trialseries_id, self.plantplot_position, self.created_on)



class Data_Standard(Base):
    __tablename__ = 'datastandard'
    
    id = Column(Integer, primary_key=True)
    name = Column(String)
    standard = Column(String)
    url = Column(String)
    doi = Column(String)
    created_on = Column(String)
    updated_on = Column(String)

    def __repr__(self):
        
        return "<Data_Standard(number='%s', name='%s', standard='%s', url='%s', doi='%s', created_on='%s')>" % \
                (self.number, self.name, self.standard, self.url, self.doi, self.created_on)
                


class Tissue(Base):
    __tablename__ = 'tissue'
    
    id = Column(Integer, primary_key=True)
    name = Column(String)
    datastandard_id = Column(Integer,ForeignKey("datastandard.id"))
    created_on = Column(String)
    updated_on = Column(String)
    
    
    def __repr__(self):
        
        return "<Tissue(name='%s', datastandard_id='%s', created_on='%s')>" % \
                (self.name, self.datastandard_id, self.created_on)


class Stage(Base):
    __tablename__ = 'samplestage'
    
    id = Column(Integer, primary_key=True)
    name = Column(String)
    datastandard_id = Column(Integer,ForeignKey("datastandard.id"))
    created_on = Column(String)
    updated_on = Column(String)
    
    
    def __repr__(self):
        
        return "<Stage(name='%s', datastandard_id='%s', created_on='%s')>" % \
                (self.name, self.datastandard_id, self.created_on)



class Samples(Base):
    __tablename__ = 'plantsample'

    id = Column(Integer, primary_key=True)
    name = Column(String)
    parentsample_id = Column(Integer)
    plantplot_id = Column(Integer,ForeignKey("plantplot.id"))
    altname = Column(String)
    tissue_id = Column(Integer)
    samplestage_id = Column(Integer)
    experimenttypes_id = Column(Integer)
    weight = Column(Float)
    sampled_on = Column(String)       
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        
#        return "<Samples(number = '%s', parentsample_id = '%d', plantplot_id = '%d', altname = '%s', tissue_id = '%d', samplestage_id = '%d', sampled_on = '%s', weight = '%.2f created_on='%s')" % \
#                (self.number, self.parentsample_id, self.plantplot_id, self.altname, self.tissue_id, self.samplestage_id, self.sampled_on, self.weight, self.created_on)        
        return "<Samples(name = '%s', plantplot_id = '%s', altname = '%s', weight = '%s', created_on='%s')>" % \
                (self.name, self.plantplot_id, self.altname, self.weight, self.created_on)        
        


class Taxa(Base):
    __tablename__ = 'taxonomies'
    
    id = Column(Integer, primary_key=True)
    genus = Column(String)
    species = Column(String)
    species_author = Column(String)
    cropname = Column(String)
    ploidy = Column(Integer)
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        return "<Taxa(genus='%s', species='%s', species_author='%s',cropname='%s', ploidy='%d', created_on='%s')>" % \
                (self.genus, self.species, self.species_author, self.cropname, self.ploidy, self.created_on)


class Subtaxa(Base):
    __tablename__ = 'subtaxa'
    
    id = Column(Integer, primary_key=True)
    taxonomy_id = Column(Integer,ForeignKey("taxonomies.id"))
    subtaxa_author = Column(String)
    taxonomic_identifier = Column(String)
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        return "<Subtaxa(taxonomy_id='%d', subtaxa_author='%s', taxonomic_identifier='%s',created_on='%s')>" % \
                (self.taxonomy_id, self.subtaxa_author, self.taxonomic_identifier, self.created_on) 
    
    
    
Session = sessionmaker(bind=engine)    

connection = engine.connect()

session = Session(bind=connection)


#query = 'SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE "GES";'

#sql='SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE %s;'
#args=['%'+"GES"+'%']
#result = connection.execute(sql,args)

#sql='SELECT * FROM taxonomies JOIN subtaxa ON taxonomies.id = subtaxa.taxonomy_id;'
#args=['%'+"GES"+'%']
#result = connection.execute(sql)

#test = session.query(Taxa).join(Subtaxa)


#for row in test:
#    print(row)

#for row in result: 
    #print("Current species: %s %s" % (row['genus'], row['species']))
#connection.close()
#for row in test:
#    print(test)

#result = session.execute(test)


#for rows in result.fetchall():
#    print(rows)




sample_tracking= pd.ExcelFile("/data/temp/IWYP60_EUE_Draft_Sample_Tracking_20171220_DC.xlsx")
#test_no_unicode = [str(i) for i in test.sheet_names]
#print(test_no_unicode)
#print(test.sheet_names)



sample_tracking_accession = sample_tracking.parse("Accession")

for accrow in sample_tracking_accession.itertuples(index=True, name='Accession'):
    
    if not (pd.isnull(getattr(accrow, "Cross"))):
        acc_cross = "Cross: %s, " % (getattr(accrow, "Cross"))
    else:
        acc_cross = ""
        
    if not (pd.isnull(getattr(accrow, "Pedigree"))):
        acc_cross = "Pedigree: %s, " % (getattr(accrow, "Pedigree"))
    else:
        acc_pedigree = ""

    if not (pd.isnull(getattr(accrow, "Cid"))):
        acc_cid = "Cid: %s, " % (getattr(accrow, "Cid"))
    else:
        acc_cid = ""
    
    if not (pd.isnull(getattr(accrow, "Cid"))):
        acc_sid = "Sid: %s, " % (getattr(accrow, "Sid"))
    else:
        acc_sid = ""
        
    if not (pd.isnull(getattr(accrow, "GID"))):
        acc_gid = "Gid: %s, " % (getattr(accrow, "GID"))
    else:
        acc_gid = ""
        
    #NB: If the column has a space in the name, Python/pandas won't interpret it properly. Must use _<colnumber>
    if not (pd.isnull(getattr(accrow, "_13"))):
        acc_oid = "Other ID: %s, " % (getattr(accrow, "_13"))
    else:
        acc_oid = ""
        
    if not (pd.isnull(getattr(accrow, "_16"))):
        acc_altname1 = "Alternative Name 1: %s, " % (getattr(accrow, "_16"))
    else:
        acc_altname1 = ""
        
    if not (pd.isnull(getattr(accrow, "_17"))):
        acc_altname2 = "Alternative Name 2: %s, " % (getattr(accrow, "_17"))
    else:
        acc_altname2 = ""
        
    if not (pd.isnull(getattr(accrow, "_18"))):
        acc_altname3 = "Alternative Name 3: %s, " % (getattr(accrow, "_18"))
    else:
        acc_altname3 = ""
            
    if not (pd.isnull(getattr(accrow, "_19"))):
        acc_altid = "Alternative ID: %s, " % (getattr(accrow, "_19"))
    else:
        acc_altid = ""
        
    if not (pd.isnull(getattr(accrow, "Notes"))):
        acc_onotes = "Other Notes: %s, " % (getattr(accrow, "Notes"))
    else:
        acc_onotes = ""
        
    if not (pd.isnull(getattr(accrow, "Source"))):
        acc_source = "Source: %s, " % (getattr(accrow, "Source"))
    else:
        acc_source = ""
    
    acc_notes = "%s%s%s%s%s%s%s%s%s%s%s%s" % (acc_cross, acc_pedigree, acc_source, acc_cid, acc_sid, acc_gid, acc_oid, acc_altname1, acc_altname2, acc_altname3, acc_altid, acc_onotes)
    acc = Accession(general_identifier=getattr(accrow, "Accession_ID"), number=getattr(accrow, "Accession_ID"), name=getattr(accrow, "Accession_name"), biologicalstatus_id=400, taxonomy_id=1, created_on=datetime.datetime.now(), notes=acc_notes)

    #print(acc_notes)
    #print(acc)
    session.add(acc)
#    NB: Country of Origin will need to go into notes... Unless there is another way of doign it?



session.commit()



sample_tracking_experiments = sample_tracking.parse("Experiment")

for exprow in sample_tracking_experiments.itertuples(index=True, name='Experiments'):
    if not pd.isnull(getattr(exprow, "Experiment_Name")):     
        exp = Experiments(experiment_number=getattr(exprow, "Experiment_ID"), experiment_name=getattr(exprow, "Experiment_Name"), description=getattr(exprow, "Experiment_Name"), experiment_type_id=3, created_on=datetime.datetime.now())
        session.add(exp)
        session.commit()
        experimentsquery = session.query(Experiments.id).filter(Experiments.experiment_name == getattr(exprow, "Experiment_Name"))
        experimentResult = session.execute(experimentsquery)
        expdesign = ExperimentDesign(name=(getattr(exprow, "Experiment_Name")+"_Design"), experiments_id=experimentResult.scalar(), created_on=datetime.datetime.now())
        session.add(expdesign)
        session.commit()








sample_tracking_plantplot = sample_tracking.parse("Plant_Plot")

#print(sample_tracking_plantplot)
#
for prow in sample_tracking_plantplot.itertuples(index=True, name='Plant_Plot'):
    if not pd.isnull(getattr(prow, "Accession_ID")): 
        
        if pd.isnull(getattr(prow, "PlantPlot_Name")):
            ppname = ""
        else:
            ppname = getattr(prow, "PlantPlot_Name")
      
#        if (getattr(prow, "Accession_ID") in "N/A"):
#            pquery=session.query(Accession.id).filter(Accession.general_identifier == "IW_A0000")
#            print(session.execute(pquery).scalar())
#        else:
#            pquery=session.query(Accession.id).filter(Accession.general_identifier == getattr(prow, "Accession_ID"))
      
        pquery=session.query(Accession.id).filter(Accession.general_identifier == getattr(prow, "Accession_ID"))
        presult=session.execute(pquery)
        
        if (not pd.isnull(getattr(prow, "Panel"))):
            trialquery=session.query(Trial_Series.id).filter(Trial_Series.seriesname == getattr(prow, "Panel"))
            trialresult=session.execute(trialquery)
            trialOut = trialresult.scalar()
                
        expquery = session.query(ExperimentDesign.id).join(Experiments).filter(Experiments.experiment_number == getattr(prow, "Experiment_ID"))
        expresult = session.execute(expquery)
        
        
        if (not pd.isnull(getattr(prow, "Experiment_Location"))):
            if getattr(prow, "Experiment_Location").find("Obregon") != -1:
                exploc = 2
            elif getattr(prow, "Experiment_Location").find("ACPFG") != -1:
                exploc = 3
            elif getattr(prow, "Experiment_Location").find("Birdcage") != -1:
                exploc = 5
            elif getattr(prow, "Experiment_Location").find("GES17") != -1:
                exploc = 1
            elif getattr(prow, "Experiment_Location").find("GES_CR4") != -1:
                exploc = 1

        ppload = Plant_Plot(number=getattr(prow, "PlantPlot_ID"), name=ppname, germinatebase_id=presult.scalar(), experimentdesign_id=expresult.scalar(), trialseries_id=trialOut, locations_id=exploc, created_on=datetime.datetime.now())
       
        session.add(ppload)
#        print(ppload)



session.commit()



sample_tracking_sample = sample_tracking.parse("Sample")

for srow in sample_tracking_sample.itertuples(index=True, name='Sample'):

    if not pd.isnull(getattr(srow, "PlantPlot_ID")): 
        squery = session.query(Plant_Plot.id).filter(Plant_Plot.number == getattr(srow, "PlantPlot_ID"))
    else:
        squery = session.query(Plant_Plot.id).filter(Plant_Plot.number == "Unknown")
    
    sresult = session.execute(squery)


    if not (pd.isnull(getattr(srow, "Tissue"))):
        tissuequery = session.query(Tissue.id).filter(Tissue.name == getattr(srow, "Tissue"))
    else:
        tissuequery = session.query(Tissue.id).filter(Tissue.name == "Unknown")
    
    tissueresult = session.execute(tissuequery)
    

    if not (pd.isnull(getattr(srow, "Stage"))):
        stagequery = session.query(Stage.id).filter(Stage.name == getattr(srow, "Stage"))
    else:
        stagequery = session.query(Stage.id).filter(Stage.name == "Unknown")
    
    stageresult = session.execute(stagequery)
    
        
    if not (pd.isnull(getattr(srow, "Sample_Name"))):
        sname = getattr(srow, "Sample_Name")
    else:
        sname = ""


    sload = Samples(name = getattr(srow, "Sample_ID"), plantplot_id = sresult.scalar(), altname = sname, tissue_id = tissueresult.scalar(), samplestage_id = stageresult.scalar())
    session.add(sload)


session.commit()



sample_tracking_sample = sample_tracking.parse("Sample")   

for trow in sample_tracking_sample.itertuples(index=True, name='Sample'):
    
    if not pd.isnull(getattr(trow, "Parent_ID")): 
        pquery = session.query(Samples.id).filter(Samples.name == getattr(trow, "Parent_ID"))
    else:
        pquery = session.query(Samples.id).filter(Samples.name == "No Parent")
        
    presult = session.execute(pquery)
    
    
    pupdate = session.query(Samples).filter(Samples.name == getattr(trow, "Sample_ID")).first()
    pupdate.parentsample_id = presult.scalar()
    session.add(pupdate)
    session.commit()




#load Plant_Plot: 

#Mapping: Spreadsheet --- Germinate

#PlantPlot_ID --- plantplot.number
#PlantPlot_Name -- plantplot.name
#Accession_ID --- germinatebase.id
#Accession_Name --- <Derived from Accession.id>
#Experiment_ID --- experiments.id
#AGG_ID --- ???
#Tray_Number --- experimentdesign.plotchamberbench
#Tray_Position --- plantplot.position
#Chamber_Position --- experimentdesign.plotchamberbench
#Experiment_Location --- plantplot.position
#FieldColumn_Number --- experimentdesign.plotchamberbench
#FieldRow_Number --- experimentdesign.row
#FieldBlock_Number --- experimentdesign.row
#Panel --- trialseries.id
#Panel_Plot --- experimentdesign.plotchamberbench
#GrainPacket_ID --- <Derived from the grainpacket table>



    
#load Experiment:

#Mapping: Spreadsheet --- Germinate

#Experiment_ID --- experiments.experiment_number
#User --- <From Gatekeeper user.id>
#Experiment_Name --- experiments.experiment_name
#plantID-START <NOT NEEDED - SQL Query on PlantSample>
#plantID-END <NOT NEEDED - SQL Query on PlantSample>
#start_date --- experiments.experiment_date
#end_date --- experiments.experiment_enddate
#Location --- <SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE "%<field>%";>
#NB experiment_type_id='3'

    
    

#sample_tracking_accessions.head()

#print(sqlalchemy.__version__)

#load Accessions...

# Mapping: Spreadsheet --- Germinate

# *** Accession_ID --- germinatebase.number
# *** Accession_name --- germinatebase.name
#Panel --- <NOT IN HERE - UNDER PLANTPLOT!>
#Genus --- taxonomies.id
#Species --- taxonomies.id
#Subspecies --- subtaxa.id
#Source --- institution.id
# *** Cross --- <ADD TO NOTES IF NOT EMPTY>
#Pedigree --- pedigree.id
# *** Cid --- <ADD TO NOTES IF NOT EMPTY>
# *** Sid --- <ADD TO NOTES IF NOT EMPTY>
# *** GID --- <ADD TO NOTES IF NOT EMPTY>
# *** Other ID --- --- <ADD TO NOTES IF NOT EMPTY>
#Country_Origin --- <SELECT id FROM countries WHERE (country_name=<field> OR country_code2=<field> OR country_code3=<field>); IF EMPTY, countries.id="-1">
# *** Alternative Name 1 --- <ADD TO NOTES IF NOT EMPTY>
# *** Alternative Name 2 --- <ADD TO NOTES IF NOT EMPTY>
# *** Alternative Name 3 --- <ADD TO NOTES IF NOT EMPTY>
# *** Alternative ID --- <ADD TO NOTES IF NOT EMPTY>
# *** Notes --- <ADD TO NOTES IF NOT EMPTY>



#load Plant_Plot: 

#Mapping: Spreadsheet --- Germinate

#PlantPlot_ID --- plantplot.number
#PlantPlot_Name -- plantplot.name
#Accession_ID --- germinatebase.id
#Accession_Name --- <Derived from Accession.id>
#Experiment_ID --- experiments.id
#AGG_ID --- ???
#Tray_Number --- experimentdesign.plotchamberbench
#Tray_Position --- plantplot.position
#Chamber_Position --- experimentdesign.plotchamberbench
#Experiment_Location --- plantplot.position
#FieldColumn_Number --- experimentdesign.plotchamberbench
#FieldRow_Number --- experimentdesign.row
#FieldBlock_Number --- experimentdesign.row
#Panel --- trialseries.id
#Panel_Plot --- experimentdesign.plotchamberbench
#GrainPacket_ID --- <Derived from the grainpacket table>



#load Sample:

#Mapping: Spreadsheet --- Germinate

#Sample_ID --- plantsample.name
#PlantPlot_ID --- plantplot.id
#Plant_Name --- <Derived from plantplot.id>
#Accession_ID --- <Derived from plantplot.id>
#Experiment_ID --- <Derived from plantplot.id>
#Experiment_Name --- <Derived from experiment.id>
#Parent_ID --- plantsample.parent_id (if no parent, ID=1)
#Sample_Name --- plantsample.altname
#Sample Type --- tissue.id
#Purpose --- experimenttypes.id
#Sample_Weight --- plantsample.weight
#Date_Harvested --- <Half of plantsample.sampled_on>
#Time_Harvested --- <Half of plantsample.sampled_on>
#Storage Location --- <SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE "%<field>%";>
#Notes --- plantsample.details



#load GrainPacket:

#Mapping: Spreadsheet --- Germinate
#
#GrainPacket_ID --- grainpacket.name
#Accession_ID --- <NOT NEEDED - Derived from plantplot/germinatebase>
#Accession_Name --- <NOT NEEDED - Derived from plantplot/germinatebase>
#Source_Experiment_ID --- experiments.id
#Source_Experiment_Name --- <Derived from experiments.id>
#Havest_Date --- grainpacket.obtained
#Growth_Location --- <SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE "%<field>%";
#Source --- <SELECT id FROM locations WHERE locations.site_name OR locations.site_name_short LIKE "%<field>%";
#PlantPlot_ID --- plantplot.id
#PlantPlot_Name --- <Derived from plantplot.id>


#print("complete")
