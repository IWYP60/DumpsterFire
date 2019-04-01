import pandas as pd
from sqlalchemy import Column, Integer, String, ForeignKey, and_
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine
import logging
import datetime


logging.basicConfig()
#logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

engine_str = "mysql://iwyp60:<password>@<server>:3306/iwyp60_germinate_dev"

engine = create_engine(engine_str, echo=False, isolation_level="READ UNCOMMITTED")

Base = declarative_base()


processAccession = False
processPlantPlot = False
processExperiments = False
processSamples = True
processGrain = False

loadQ2Data = False


if processExperiments:

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



if any([processAccession,processPlantPlot,processSamples,processGrain]):

    class EntityType(Base):
        __tablename__ = 'entitytype'
        
        id = Column(Integer, primary_key=True)
        name = Column(String)
        description = Column(String)
        created_on = Column(String)
        updated_on = Column(String)
            
        def __repr__(self):
            return "<Entities(Name='%s', description='%s', created_on='%s')>" % (self.name, self.description, self.created_on)
    
    
    #Should happen with ANY process flag
    
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
    
    #NB: This is here so that the data file is loaded ONLY if Accession processing is on the list.

class AttributeData(Base):
    __tablename__ = 'attributedata'
    
    id = Column(Integer, primary_key=True)
    attribute_id = Column(Integer,ForeignKey("attributes.id"))
    foreign_id = Column(Integer) #NB: not a TRUE Foreign Key. More like a reference to another table index
    value = Column(String)
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        return "<Subtaxa(attribute_id='%d', foreign_id='%d', value='%s',created_on='%s')>" % \
                (self.attribute_id, self.foreign_id, self.value, self.created_on)

                

class Attributes(Base):
    __tablename__ = 'attributes'
    
    id = Column(Integer, primary_key=True)
    name = Column(String)
    description = Column(String)
    datatype = Column(String) #NB: FIXED LIST - INT, FLOAT, CHAR
    target_table = Column(String)
    created_on = Column(String)
    updated_on = Column(String)
    
    def __repr__(self):
        return "<Subtaxa(name='%s', description='%d', datatype='%s', target_table='%s',created_on='%s')>" % \
                (self.name, self.description, self.datatype, self.target_table, self.created_on)
                



sample_tracking = pd.ExcelFile("/data/temp/IWYP60_EUE_Draft_Sample_Tracking_20180605_SHP_copy.xlsx")    
    
Session = sessionmaker(bind=engine)    

connection = engine.connect()

session = Session(bind=connection)





if processAccession:
    
    print "Loading Accession data, ignoring existing entries"
    sample_tracking_accession = sample_tracking.parse("Accession")
    
    
    
    for accrow in sample_tracking_accession.itertuples(index=True, name='Accession'):
        
        acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
        acc_existing_result=session.execute(acc_existing_query).scalar()
        
        if acc_existing_result:
            next
        else:


                
            #acc_notes = "%s%s%s%s%s%s%s%s%s%s%s%s" % (acc_cross, acc_pedigree, acc_source, acc_cid, acc_sid, acc_gid, acc_oid, acc_altname1, acc_altname2, acc_altname3, acc_altid, acc_onotes)
            acc = GerminateBase(general_identifier=getattr(accrow, "Accession_ID"), number=getattr(accrow, "Accession_ID"), name=getattr(accrow, "Accession_name"), entitytype_id = 1, biologicalstatus_id=400, taxonomy_id=1, created_on=datetime.datetime.now())#, notes=acc_notes)
            session.add(acc)
            
        #    NB: Country of Origin will need to go into notes... Unless there is another way of doign it?
    
    
    print ('%d accession entries added to Germinate') % len(session.new)
    session.commit()


if processAccession:
    
    print "Loading parental and attribute data for accession entries"
    
    for accrow in sample_tracking_accession.itertuples(index=True, name='Accession'):
        accparentquery = None
        

        if not (pd.isnull(getattr(accrow, "Parent_ID"))):
            accparentquery=session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(accrow, "Parent_ID"))
            accparentresult=session.execute(accparentquery).scalar()
            
            session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID")).update({"entityparent_id":accparentresult})


        if not (pd.isnull(getattr(accrow, "Source"))):

            source = getattr(accrow, "Source")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_source_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 3,AttributeData.foreign_id == acc_existing_result, AttributeData.value == source))
            acc_source_result=session.execute(acc_source_query).first()
            
            if (acc_source_result == None):               
                acc_source = AttributeData(attribute_id = 3, foreign_id = acc_existing_result, value = source, created_on=datetime.datetime.now())
                session.add(acc_source)


        if not (pd.isnull(getattr(accrow, "Cross"))):           
            cross = getattr(accrow, "Cross")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_cross_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 1,AttributeData.foreign_id == acc_existing_result, AttributeData.value == cross))
            acc_cross_result=session.execute(acc_cross_query).first()
            
            
            if (acc_cross_result == None):               
                acc_cross = AttributeData(attribute_id = 1, foreign_id = acc_existing_result, value = cross, created_on=datetime.datetime.now())
                session.add(acc_cross)


        if not (pd.isnull(getattr(accrow, "Pedigree"))):
            pedigree = getattr(accrow, "Pedigree")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_pedigree_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 2,AttributeData.foreign_id == acc_existing_result, AttributeData.value == pedigree))
            acc_pedigree_result=session.execute(acc_pedigree_query).first()
                        
            if (acc_pedigree_result == None):               
                acc_pedigree = AttributeData(attribute_id = 2, foreign_id = acc_existing_result, value = pedigree, created_on=datetime.datetime.now())
                session.add(acc_pedigree)


        if not (pd.isnull(getattr(accrow, "Cid"))):
            cid = getattr(accrow, "Cid")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_cid_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 4,AttributeData.foreign_id == acc_existing_result, AttributeData.value == cid))
            acc_cid_result=session.execute(acc_cid_query).first()
                        
            if (acc_cid_result == None):                
                acc_cid = AttributeData(attribute_id = 4, foreign_id = acc_existing_result, value = cid, created_on=datetime.datetime.now())
                session.add(acc_cid)


        if not (pd.isnull(getattr(accrow, "Sid"))):
            sid = getattr(accrow, "Sid")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_sid_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 5,AttributeData.foreign_id == acc_existing_result, AttributeData.value == sid))
            acc_sid_result=session.execute(acc_sid_query).first()
            
            if (acc_sid_result == None):
                acc_sid = AttributeData(attribute_id = 5, foreign_id = acc_existing_result, value = sid, created_on=datetime.datetime.now())
                session.add(acc_sid)


        if not (pd.isnull(getattr(accrow, "GID"))):

            gid = getattr(accrow, "GID")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_gid_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 6,AttributeData.foreign_id == acc_existing_result, AttributeData.value == gid))
            acc_gid_result=session.execute(acc_gid_query).first()
            
            if (acc_gid_result == None):
                acc_gid = AttributeData(attribute_id = 6, foreign_id = acc_existing_result, value = gid, created_on=datetime.datetime.now())
                session.add(acc_gid)


        if not (pd.isnull(getattr(accrow, "_14"))):

            oid = getattr(accrow, "_14")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_oid_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 7,AttributeData.foreign_id == acc_existing_result, AttributeData.value == oid))
            acc_oid_result=session.execute(acc_oid_query).first()
            
            if (acc_oid_result == None):
                acc_oid = AttributeData(attribute_id = 7, foreign_id = acc_existing_result, value = oid, created_on=datetime.datetime.now())
                session.add(acc_oid)


        if not (pd.isnull(getattr(accrow, "_17"))):

            altname1 = getattr(accrow, "_17")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_altname1_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 8,AttributeData.foreign_id == acc_existing_result, AttributeData.value == altname1))
            acc_altname1_result=session.execute(acc_altname1_query).first()
            
            if (acc_altname1_result == None):
                acc_altname1 = AttributeData(attribute_id = 8, foreign_id = acc_existing_result, value = altname1, created_on=datetime.datetime.now())
                session.add(acc_altname1)


        if not (pd.isnull(getattr(accrow, "_18"))):

            altname2 = getattr(accrow, "_18")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_altname2_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 9,AttributeData.foreign_id == acc_existing_result, AttributeData.value == altname2))
            acc_altname2_result=session.execute(acc_altname2_query).first()
            
            if (acc_altname2_result == None):
                acc_altname2 = AttributeData(attribute_id = 9, foreign_id = acc_existing_result, value = altname2, created_on=datetime.datetime.now())
                session.add(acc_altname2)


        if not (pd.isnull(getattr(accrow, "_19"))):

            altname3 = getattr(accrow, "_19")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_altname3_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 10,AttributeData.foreign_id == acc_existing_result, AttributeData.value == altname3))
            acc_altname3_result=session.execute(acc_altname1_query).first()
            
            if (acc_altname3_result == None):
                acc_altname3 = AttributeData(attribute_id = 10, foreign_id = acc_existing_result, value = altname3, created_on=datetime.datetime.now())
                session.add(acc_altname3)


        if not (pd.isnull(getattr(accrow, "_20"))):

            altid = getattr(accrow, "_20")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_altid_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 11,AttributeData.foreign_id == acc_existing_result, AttributeData.value == altid))
            acc_altid_result=session.execute(acc_altid_query).first()
            
            if (acc_altid_result == None):
                acc_altid = AttributeData(attribute_id = 11, foreign_id = acc_existing_result, value = altid, created_on=datetime.datetime.now())
                session.add(acc_altid)


        if not (pd.isnull(getattr(accrow, "Notes"))):

            notes = getattr(accrow, "Notes")
            acc_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(accrow, "Accession_ID"))
            acc_existing_result=session.execute(acc_existing_query).scalar()
            
            acc_notes_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 12,AttributeData.foreign_id == acc_existing_result, AttributeData.value == notes))
            acc_notes_result=session.execute(acc_notes_query).first()
            
            if (acc_notes_result == None):
                acc_notes = AttributeData(attribute_id = 12, foreign_id = acc_existing_result, value = notes, created_on=datetime.datetime.now())
                session.add(acc_notes)

    session.commit()




if processExperiments:
    
    print "Loading Experiments, ignoring existing entries"
    sample_tracking_experiments = sample_tracking.parse("Experiment")


    for exprow in sample_tracking_experiments.itertuples(index=True, name='Experiments'):
        
        exp_exist_result = None

        exp_exist_query=session.query(Experiments.id).filter(Experiments.experiment_name==getattr(exprow, "Experiment_ID"))
        exp_exist_result=session.execute(exp_exist_query).scalar()
        
        if exp_exist_result:
            next
        else:
            if not pd.isnull(getattr(exprow, "Experiment_Name")):     
                exp = Experiments(experiment_name=getattr(exprow, "Experiment_ID"), description=getattr(exprow, "Experiment_Name"), experiment_type_id=3, created_on=datetime.datetime.now())
                session.add(exp)
        
    print ('%d experiments added to Germinate') % len(session.new)
    
    session.commit()




if processPlantPlot:
    
    print "Loading PlantPlot data, ignoring existing entries"

    sample_tracking_plantplot = sample_tracking.parse("Plant_Plot")
    
    
    for prow in sample_tracking_plantplot.itertuples(index=True, name='Plant_Plot'):
        
               
        plant_exist_result = None

        plant_exist_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier==getattr(prow, "PlantPlot_ID"))
        plant_exist_result=session.execute(plant_exist_query).scalar()
        
        if plant_exist_result:
            next
        else:
        
            if not pd.isnull(getattr(prow, "Accession_ID")): 
                
                if pd.isnull(getattr(prow, "PlantPlot_Name")):
                    ppname = ""
                else:
                    ppname = getattr(prow, "PlantPlot_Name")
        
              
                pquery=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(prow, "Accession_ID"))
                presult=session.execute(pquery).scalar()
        
                
                if (not pd.isnull(getattr(prow, "Panel"))):
                    trialquery=session.query(Trial_Series.id).filter(Trial_Series.seriesname == getattr(prow, "Panel"))
                    trialresult=session.execute(trialquery)
                    trialOut = trialresult.scalar()
        
                
                if (not pd.isnull(getattr(prow, "Experiment_Location"))):
                    if getattr(prow, "Experiment_Location").find("Acacia") != -1:
                        exploc = 4
                    elif getattr(prow, "Experiment_Location").find("Obregon") != -1:
                        exploc = 2
                    elif getattr(prow, "Experiment_Location").find("ACPFG") != -1:
                        exploc = 3
                    elif getattr(prow, "Experiment_Location").find("Birdcage") != -1:
                        exploc = 5
                    elif getattr(prow, "Experiment_Location").find("GES17") != -1:
                        exploc = 1
                    elif getattr(prow, "Experiment_Location").find("GES_CR4") != -1:
                        exploc = 1
                    elif getattr(prow, "Experiment_Location").find("Naracoorte, SA") != -1:
                        exploc = 7
                    elif getattr(prow, "Experiment_Location").find("GES 2018") != -1:
                        exploc = 6    
                        
     
                if (not pd.isnull(getattr(prow, "PlantPlot_Name"))):
                    plantplotname = getattr(prow, "PlantPlot_Name")
                else:
                    plantplotname = ""
                

            ppload = GerminateBase(general_identifier=getattr(prow, "PlantPlot_ID"), number=getattr(prow, "PlantPlot_ID"), name = plantplotname,entitytype_id=2, entityparent_id=presult)
            session.add(ppload)
    
    print ('%d PlantPlot entries added to Germinate') % len(session.new)
    session.commit()

#NB: The attributes table data must be performed as part of processing samples.
#NB: All samples and need to be added to the database BEFORE adding the parents.

if processSamples:
    
    print "Loading Sample data, ignoring existing entries"
    
    sample_tracking_sample = sample_tracking.parse("Sample")

    
    #NB: If there is a sample Parent_ID AND a PlantPlot_ID, the parent sample needs to be the one used as the parent
    for srow in sample_tracking_sample.itertuples(index=True, name='Sample'):
        
        
        sample_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(srow, "Sample_ID"))
        sample_existing_result=session.execute(sample_existing_query).scalar()
        
        
        if sample_existing_result:
            next
        else:
        
            entityIndex = None
            sampleType = ""
            samplePurpose = ""
                
            
    
            if (not pd.isnull(getattr(srow, "Notes"))) and (str(getattr(srow, "Notes").encode('utf-8')) == "Surplus Sample Number"):
                #NB: This is to skip any of the blank/unused sample numbers tagged with "Surplus Sample Number"
                next
            else:
               
                if (type(getattr(srow, "Sample_Name")) == float):
                    sampleName = str(getattr(srow, "Plant_Name").encode('utf-8'))
                else:
                    sampleName = str(getattr(srow, "Sample_Name").encode('utf-8'))
    
                sload = GerminateBase(general_identifier=str(getattr(srow, "Sample_ID").encode('utf-8')), number=str(getattr(srow, "Sample_ID").encode('utf-8')), name=sampleName, entitytype_id = 3, biologicalstatus_id=400, collsrc_id=40, taxonomy_id=1, created_on=datetime.datetime.now())   
                session.add(sload)

    
    print ('%d Sample entries added to Germinate') % len(session.new)
    session.commit()
    

    
    
if processSamples:
    
    print "Loading sample types"
    
    sample_tracking_sample = sample_tracking.parse("Sample")
    
    for srow in sample_tracking_sample.itertuples(index=True, name='Sample'):
        sample_notes_result = None
                
        
        if (not pd.isnull(getattr(srow, "Notes"))) and (str(getattr(srow, "Notes").encode('utf-8')) == "Surplus Sample Number"):
            next

        else:

            sample_existing_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == getattr(srow, "Sample_ID"))
            sample_existing_result=session.execute(sample_existing_query).scalar()
            
                
            if not pd.isnull(getattr(srow, "_9")):
                sampleType = str(getattr(srow, "_9").encode('utf-8').lower())            
            
            # Purpose of sample
            if not pd.isnull(getattr(srow, "Purpose")):
                samplePurpose = str(getattr(srow, "Purpose").encode('utf-8').lower())                
            
            
            #Calculate what database type entry is assigned to each sampleType and samplePurpose entry
            if (sampleType == "" and samplePurpose == ""): 
                next
            
                # "Backup" sample
            elif (samplePurpose == "backup"):
                sample_type = "Backup"
                
                # Dried Q2 Sample
            elif ("q2" in samplePurpose):
                sample_type = "Q2"
                
                # Frozen sample (pre Prot/Met/DNA)
            elif (("frozen leaf" in sampleType) and ((samplePurpose == "") or (samplePurpose == "prot/met") or (samplePurpose == "tissue sample"))):
                sample_type = "Frozen Leaf"
                
                # DNA sample
            elif ((samplePurpose == "genotyping") or (samplePurpose == "dna") or (sampleType == "dna")):
                sample_type = "DNA Extraction"
                
                # Metabolomic sample
            elif (samplePurpose == "metabolomics"):
                sample_type = "Metabolomics"
                
                # Proteomic sample
            elif (samplePurpose == "proteomics"):
                sample_type = "Proteomics"
                
                # Original leaf sample from the field
            elif ("original leaf" in samplePurpose):
                sample_type = "Original Leaf"


            sample_type_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 13,AttributeData.foreign_id == sample_existing_result, AttributeData.value == sample_type))
            sample_type_result=session.execute(sample_type_query).first()
                
            if (sample_type_result == None):
                                
                sample_type = AttributeData(attribute_id = 13, foreign_id = sample_existing_result, value = sample_type, created_on=datetime.datetime.now())
                session.add(sample_type)
            
                          
        if (not pd.isnull(getattr(srow, "Notes"))) and (not (str(getattr(srow, "Notes").encode('utf-8')) == "Surplus Sample Number")):
            
            snotes = getattr(srow, "Notes").encode('utf-8')
           
            sample_notes_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 12,AttributeData.foreign_id == sample_existing_result, AttributeData.value == snotes))
            sample_notes_result=session.execute(sample_notes_query).first()  
            
            if (sample_notes_result == None):
                sample_notes = AttributeData(attribute_id = 12, foreign_id = sample_existing_result, value = snotes, created_on=datetime.datetime.now())
                session.add(sample_notes) 
        
        
        if (pd.isnull(getattr(srow, "Tissue"))):
            stissue = "Unknown"
        else:
            stissue = getattr(srow, "Tissue").encode('utf-8')
            
            sample_tissue_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 15,AttributeData.foreign_id == sample_existing_result, AttributeData.value == stissue))
            sample_tissue_result=session.execute(sample_tissue_query).first()  
            
            if (sample_tissue_result == None):
                sample_tissue = AttributeData(attribute_id = 15, foreign_id = sample_existing_result, value = stissue, created_on=datetime.datetime.now())
                session.add(sample_tissue) 
                
        
        if (pd.isnull(getattr(srow, "Stage"))):
            sstage = "Unknown"
        else:
            sstage= getattr(srow, "Stage").encode('utf-8')
            
            sample_stage_query=session.query(AttributeData).filter(and_(AttributeData.attribute_id == 14,AttributeData.foreign_id == sample_existing_result, AttributeData.value == sstage))
            sample_stage_result=session.execute(sample_stage_query).first()  
            
            if (sample_stage_result == None):
                sample_stage = AttributeData(attribute_id = 14, foreign_id = sample_existing_result, value = sstage, created_on=datetime.datetime.now())
                session.add(sample_tissue)         
        
            
    session.commit()
    

    

if processSamples:
    
    print "Loading parental data"  
    
    for srow in sample_tracking_sample.itertuples(index=True, name='Sample'):   
        
        if (not pd.isnull(getattr(srow, "Notes"))) and (str(getattr(srow, "Notes").encode('utf-8')) == "Surplus Sample Number"):
            next

        else: 

            if (not (type(getattr(srow, "Parent_ID")) == float)):
                sampleparentquery=session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(srow, "Parent_ID"))
                sampleparentresult=session.execute(sampleparentquery).scalar()
                session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(srow, "Sample_ID")).update({"entityparent_id":sampleparentresult})                
    
            else:
                sampleparentquery=session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(srow, "PlantPlot_ID"))
                sampleparentresult=session.execute(sampleparentquery).scalar()
                session.query(GerminateBase).filter(GerminateBase.general_identifier == getattr(srow, "Sample_ID")).update({"entityparent_id":sampleparentresult})

    session.commit()




if processGrain:
    print "Loading GrainPacket data, ignoring existing entries"
    sample_tracking_grain = sample_tracking.parse("GrainPacket")
    
    
    for grow in sample_tracking_grain.itertuples(index=True, name='GrainPacket'):

        
        grain_exist_result = None
    
        grain_exist_query=session.query(GerminateBase.id).filter(GerminateBase.general_identifier==getattr(grow, "GrainPacket_ID"))
        grain_exist_result=session.execute(grain_exist_query).scalar()
        
        if grain_exist_result:
            next
        else:
        
            if (not type(getattr(grow, "PlantPlot_ID")) == float):
                
                gparent = getattr(grow, "PlantPlot_ID")
        
            else:
        
                if (not type(getattr(grow, "Accession_ID")) == float):
        
                    gparent = getattr(grow, "Accession_ID")
                    
                else:
                    continue
                 
            gname = getattr(grow, "Accession_Name")
            
            gquery=session.query(GerminateBase.id).filter(GerminateBase.general_identifier == gparent)
            gresult=session.execute(gquery).scalar()
        
        
            gload = GerminateBase(general_identifier=getattr(grow, "GrainPacket_ID"),number=getattr(grow, "GrainPacket_ID"),name=gname,entitytype_id=10,entityparent_id=gresult)
            session.add(gload)    
        
        
    print ('%d GrainPacket entries added to Germinate') % len(session.new)
    session.commit()



print("Import Complete")

print("Import Complete")
