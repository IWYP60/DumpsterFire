	

CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`datastandard` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'Type of data standard, descriptive. Must be a unique data standard name to differentiate it from others.',
  `standard` varchar(255) NOT NULL COMMENT 'The actual NAME of the data standard. For example, EPPN. Year information would be helpful in here as well',
  `url` varchar(255) COMMENT 'URL where details of the standard can be found. DIFFERENT to DOI!',
  `doi` varchar(255) COMMENT 'DOI for the documented standard',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',
  
  PRIMARY KEY (`id`),
  UNIQUE (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording details of the data standards used for sample stages and tissues. Need to record a URL or DOI of where the standard has been obtained from, otherwise, it must be considered a "custom" data standard.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`samplestage` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'The name of the stage that the sample was taken, descriptive. Must be unique to differentiate it from other stages.',
  `datastandard_id` INT(11) COMMENT 'Foreign key to datastandard (datastandard.id). If this sample stage has come from a specific nomenclature, details about what standard it adheres to.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',
  
  PRIMARY KEY (`id`),
  UNIQUE (`id`),
  KEY `datastandard_id` (`datastandard_id`) USING BTREE,
  CONSTRAINT `samplestage_ibfk_1` FOREIGN KEY (`datastandard_id`) REFERENCES `datastandard` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording details of the growth stage at which a sample was taken. This is from a SET VOCABULARY of growth stages.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`tissue` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'The name of the stage that the sample was taken, descriptive. Must be unique to differentiate it from other stages.',
  `datastandard_id` INT(11) COMMENT 'Foreign key to datastandard (datastandard.id). If this sample stage has come from a specific nomenclature, details about what standard it adheres to.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',
  
  PRIMARY KEY (`id`),
  UNIQUE (`id`),
  KEY `datastandard_id` (`datastandard_id`) USING BTREE,
  CONSTRAINT `tissue_ibfk_1` FOREIGN KEY (`datastandard_id`) REFERENCES `datastandard` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording what tissue was sampled. This is from a SET VOCABULARY of tissues for the specific sample.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`germinatefile` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'The name of the germinate file.',
  `file` blob COMMENT 'The file itself.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',

  PRIMARY KEY (`id`),
  UNIQUE (`id`)

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for storing files within the database itself. Originally for experimental design files, but can be anything.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`experimentdesign` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'The name of the experiment. Must be unique to differentiate it from other experiments. Best practive should incorporate details on year, location (or abbreviation) and a bench or plot number, especially for multiple field plots in the one growing location or multiple benches or growth chambers as part of the one experiment.',
  `plotchamberbench` varchar(45) COMMENT 'If the experimental design has multiple trays, plots or chambers, define which ones they are here.',
  `row` int(5) COMMENT 'The number of rows (even partial ones) in the layout',
  `column` int(5) COMMENT 'The number of columns (even partial ones) in the layout',
  `experiments_id` int(11) COMMENT 'Foreign key to experiments (experiments.id) linking an experiment to an experimental design',
  `notes` varchar(255) COMMENT 'Details surrounding the experimental design',
  `designfile_id` int(11) COMMENT 'Foreign key to the design file itself.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',

  PRIMARY KEY (`id`),
  UNIQUE (`id`),

  KEY `experiments_id` (`experiments_id`) USING BTREE,
  KEY `designfile_id` (`designfile_id`),
  CONSTRAINT `experimentdesign_ibfk_1` FOREIGN KEY (`experiments_id`) REFERENCES `experiments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `experimentdesign_ibfk_2` FOREIGN KEY (`designfile_id`) REFERENCES `germinatefile` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording the purpose of the sample, for example, DNA extraction, proteomics, respiration...';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`plantplot` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'Name of the individual plant. Must be a unique name to identify the plant.',
  `germinatebase_id` int(11) NOT NULL COMMENT 'Foreign key to germinatebase (germinatebase.id).',  
  `locations_id` int(11) NOT NULL COMMENT 'Foreign key to location (locations.id).',
  `experimentdesign_id` int(11) COMMENT 'Foreign key to experimentaldesign (experimentaldesign.id). The design/layout of the growth experiment',
  `plantplot_position` varchar(5) NOT NULL COMMENT 'The position within the trial that the plant is located.',
  `trialseries_id` int(11) COMMENT 'Foreign key to assign this individual plant to a specific panel or trial.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',

  
  PRIMARY KEY (`id`),
  UNIQUE (`id`),
  KEY `germinatebase_id` (`germinatebase_id`) USING BTREE,
  KEY `locations_id` (`locations_id`) USING BTREE,
  KEY `trialseries_id` (`trialseries_id`) USING BTREE,
  KEY `experimentdesign_id` (`experimentdesign_id`) USING BTREE,
  CONSTRAINT `plantplot_ibfk_1` FOREIGN KEY (`germinatebase_id`) REFERENCES `germinatebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantplot_ibfk_2` FOREIGN KEY (`locations_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantplot_ibfk_3` FOREIGN KEY (`trialseries_id`) REFERENCES `trialseries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantplot_ibfk_4` FOREIGN KEY (`experimentdesign_id`) REFERENCES `experimentdesign` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording details of individual plants. These are then linked to individual samples of these plants, which are then linked to specific genotypes.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`plantsample` (

  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'Name of the individual sample. Must be a unique name to identify the sample.',
  `plantplot_id` int(11) COMMENT 'Links to the individual plant where the sample was obtained from',
  `altname` varchar(255) COMMENT 'An alternate name for this sample.',
  `tissue_id` int(11) COMMENT 'The type of tissue this is sampled from. CONTROLLED VOCABULARY!',
  `samplestage_id` int(11) COMMENT 'The growing stage at which the plant is samples at. CONTROLLED VOCABULARY!',
  `experimenttypes_id` int(11) COMMENT 'What the sample is going to be used for. CONTROLLED VOCABULARY!',
  `weight` DOUBLE(64,10) COMMENT 'The weight of the sample. Important for proteomics and normalisation',
  `sampled_on` DATETIME COMMENT 'When the sample was taken. May be different to created on',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',  
  
  PRIMARY KEY (`id`),
  UNIQUE (`id`),
  KEY `tissue_id` (`tissue_id`) USING BTREE,
  KEY `plantplot_id`(`plantplot_id`) USING BTREE,
  KEY `samplestage_id` (`samplestage_id`) USING BTREE,
  KEY `experimenttypes_id` (`experimenttypes_id`) USING BTREE,
  
  
  CONSTRAINT `plantsample_ibfk_1` FOREIGN KEY (`plantplot_id`) REFERENCES `plantplot` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantsample_ibfk_2` FOREIGN KEY (`tissue_id`) REFERENCES `tissue` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantsample_ibfk_3` FOREIGN KEY (`samplestage_id`) REFERENCES `samplestage` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plantsample_ibfk_4` FOREIGN KEY (`experimenttypes_id`) REFERENCES `experimenttypes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE


  
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for recording details of samples from plants or plots of plants. These are then linked to individual plants, which are then linked to specific genotypes.';




CREATE TABLE IF NOT EXISTS `iwyp60_germinate_test`.`grainpacket` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Primary id for this table. This uniquely identifies the row.',
  `name` varchar(255) NOT NULL COMMENT 'The name of the germinate file.',
  `obtained` datetime COMMENT 'The date the grain was obtained or harvested.',
  `germinatebase_id` int(11) NOT NULL COMMENT 'Foreign key to germinatebase (germinatebase.id), if there is no plant information', 
  `institutions_id` INT(11) COMMENT 'The institution the grain packet was obtained from.', 
  `plantplot_id` int(11) COMMENT 'Foreign Key for the plant the grain was harvested from (if applicable).',
  `experiments_id` int(11) COMMENT 'The experiment where the grain was obtained from (if applicable).',
  `locations_id` int(11) NOT NULL COMMENT 'Foreign key to locations (locations.id).',
  `empty` tinyint(1) COMMENT 'Is the grain packet empty? True=1, False=0.',
  `created_on` datetime DEFAULT NULL COMMENT 'When the record was created.',
  `updated_on` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'When the record was updated. This may be different from the created on date if subsequent changes have been made to the underlying record.',

  PRIMARY KEY (`id`),
  UNIQUE (`id`),

  KEY `germinatebase_id` (`germinatebase_id`) USING BTREE,
  KEY `institutions_id` (`institutions_id`) USING BTREE,
  KEY `plantplot_id` (`plantplot_id`) USING BTREE,
  KEY `experiments_id` (`experiments_id`) USING BTREE,
  KEY `locations_id` (`locations_id`) USING BTREE,

  CONSTRAINT `grainpacket_ibfk_1` FOREIGN KEY (`germinatebase_id`) REFERENCES `germinatebase` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `grainpacket_ibfk_2` FOREIGN KEY (`institutions_id`) REFERENCES `institutions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `grainpacket_ibfk_3` FOREIGN KEY (`plantplot_id`) REFERENCES `plantplot` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `grainpacket_ibfk_4` FOREIGN KEY (`experiments_id`) REFERENCES `experiments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `grainpacket_ibfk_5` FOREIGN KEY (`locations_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE


) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='Table for storing files within the database itself. Originally for experimental design files, but can be anything.';


ALTER TABLE `iwyp60_germinate_test`.`phenotypedata` ADD COLUMN `plantsample_id` int(11) NOT NULL DEFAULT '0' AFTER `trialseries_id`;
ALTER TABLE `iwyp60_germinate_test`.`phenotypedata` ADD CONSTRAINT `phenotypedata_ibfk_7`  FOREIGN KEY (`plantsample_id`)  REFERENCES `iwyp60_germinate_test`.`plantsample` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

  
ALTER TABLE `iwyp60_germinate_test`.`plantsample` ADD COLUMN `parentsample_id` int(11) AFTER `name`;
ALTER TABLE `iwyp60_germinate_test`.`plantsample` COMMENT 'The parent sample where this was obtained from, if applicable.';
ALTER TABLE `iwyp60_germinate_test`.`plantsample` ADD KEY `parentsample_id` (`parentsample_id`) USING BTREE;
ALTER TABLE `iwyp60_germinate_test`.`plantsample` ADD CONSTRAINT `plantsample_ibfk_5` FOREIGN KEY (`parentsample_id`) REFERENCES `plantsample` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
