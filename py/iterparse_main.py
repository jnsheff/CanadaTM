#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# A streaming xml parser to extract data for Canada Trademarks Dataset Main file.
# To be executed after CIPO-Canada's IP Horizons Trademark Bulk Data has been 
# downloaded and processed using sftp-secure.py

import os
from tqdm import tqdm
import csv
import lxml
from lxml import etree
import re
from pathlib import Path

def main():
    
    # create an xml namespace dictionary for the parser
    
    ns_dict = {
        'catmk' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark",
        'com' : "http://www.wipo.int/standards/XMLSchema/ST96/Common",
        'cacom' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common",
        'tmk' : "http://www.wipo.int/standards/XMLSchema/ST96/Trademark" 
    }

    # Create a dictionary of destination data fields and associated XPath expressions for which data will be extracted
    
    tagNeeds = {
        'AppNo':        etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ExtNo':        etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'TMText':       etree.XPath('.//tmk:MarkSignificantVerbalElementText/text()', namespaces = ns_dict, smart_strings=False),
        'TMDesc':       etree.XPath('.//tmk:MarkDescriptionText/text()', namespaces = ns_dict, smart_strings=False),
        'RegNo':        etree.XPath('.//tmk:Trademark/com:RegistrationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'MadridNo':     etree.XPath('.//tmk:InternationalMarkIdentifier/text()', namespaces = ns_dict, smart_strings=False),
        'MarkType':     etree.XPath('.//tmk:MarkRepresentation/tmk:MarkFeatureCategory/text()', namespaces = ns_dict, smart_strings=False),
        'MarkClassCode': etree.XPath('.//catmk:TrademarkClassCode/text()', namespaces = ns_dict, smart_strings=False),
        'MarkClassDesc': etree.XPath('.//catmk:TrademarkClassDescription[@com:languageCode="en"]/text()', namespaces = ns_dict, smart_strings=False),
        'LegisCode':    etree.XPath('.//catmk:LegislationCode/text()', namespaces = ns_dict, smart_strings=False),
        'LegisDesc':    etree.XPath('.//catmk:LegislationDescription[@com:languageCode="en"]/text()', namespaces = ns_dict, smart_strings=False),
        'StanChar':     etree.XPath('.//tmk:MarkStandardCharacterIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'CurrStatus':   etree.XPath('.//tmk:MarkCurrentStatusInternalDescriptionText/text()', namespaces = ns_dict, smart_strings=False),
        'StatusDate':   etree.XPath('.//tmk:MarkCurrentStatusDate/text()', namespaces = ns_dict, smart_strings=False),
        'AppDate':      etree.XPath('.//com:ApplicationDate/text()', namespaces = ns_dict, smart_strings=False),
        'PubDate':      etree.XPath('.//tmk:PublicationActionDate/text()', namespaces = ns_dict, smart_strings=False),
        'AllowDate':    etree.XPath('.//catmk:AllowedDate/text()', namespaces = ns_dict, smart_strings=False),
        'AbanDate':     etree.XPath('.//tmk:ApplicationAbandonedDate/text()', namespaces = ns_dict, smart_strings=False),
        'RegDate':      etree.XPath('.//com:RegistrationDate/text()', namespaces = ns_dict, smart_strings=False), 
        'Canceln':      etree.XPath('.//tmk:CancellationProceedings', namespaces = ns_dict, smart_strings=False),
        'Oppn':         etree.XPath('.//tmk:OppositionProceedingBag', namespaces = ns_dict, smart_strings=False),
        'Doubtful':     etree.XPath('.//catmk:DoubtfulCaseBag', namespaces = ns_dict, smart_strings=False),
        'RenewedDate':  etree.XPath('.//com:RenewalDate/text()', namespaces = ns_dict, smart_strings=False),
        'TermDate':     etree.XPath('.//tmk:TerminationDate/text()', namespaces = ns_dict, smart_strings=False), # NB: This element is mislabeled in the CIPO data spec: the spec lists the namespace as com
        'AcquiredDist': etree.XPath('.//tmk:TradeDistinctivenessIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'ForeignAppBasis': etree.XPath('.//tmk:BasisForeignApplicationIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'ForeignRegBasis': etree.XPath('.//tmk:BasisForeignRegistrationIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'UseBasis':     etree.XPath('.//tmk:BasisUseIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'ITUBasis':     etree.XPath('.//tmk:BasisIntentToUseIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'NoBasis':      etree.XPath('.//tmk:NoBasisIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'UseEvid':      etree.XPath('.//tmk:UseRightIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'NonUse':       etree.XPath('.//tmk:NonUseCancelledIndicator/text()', namespaces = ns_dict, smart_strings=False),
        'Disclaimer':   etree.XPath('.//tmk:MarkDisclaimerText/text()', namespaces = ns_dict, smart_strings=False),
        'Restriction':  etree.XPath('.//tmk:UseLimitationText/text()', namespaces = ns_dict, smart_strings=False),
        'OwnerName':    etree.XPath('.//tmk:ApplicantBag/tmk:Applicant/com:LegalEntityName/text()', namespaces = ns_dict, smart_strings=False),
        'Section9Code': etree.XPath('.//catmk:Section9Code/text()', namespaces = ns_dict, smart_strings=False),
        'Section9Desc': False,
        'GICode':       etree.XPath('.//catmk:GeographicalIndicationKindCategory/cacom:CategoryCode/text()', namespaces = ns_dict, smart_strings=False),
        'GIDesc':       False
        }
    
    # identify fields for which only indicator variables are sought in this dataset
    booleanList = ['Disclaimer', 'Oppn', 'Canceln', 'Doubtful', 'Restriction', 'NoBasis']

    # create dictionary mapping Section 9 paragraph descriptors to codes

    section9map = {
        '1' : 'Paragraph 9(1)(e) - Government Flags',
        '2' : 'Subparagraph 9(1)(n)(i) - Her Majesties Forces',
        '3' : 'Subparagraph 9(1)(n)(ii) - Universities',
        '4' : 'Subparagraph 9(1)(n)(iii) - Public Authorities in Canada for specific goods and services',
        '5' : 'Paragraph 9(1)(n.1) - Armorial Emblems',
        '6' : 'Paragraph 9(1)(i) - Foreign Government Flags and Symbols and 6ter applications',
        '7' : 'Paragraph 9(1)(i.1) - 6ter - Official Sign or Hallmark',
        '8' : 'Paragraph 9(1)(i.3) - 6ter - Armorial Bearing/Emblem or Abbreviation of Name',
        '9' : 'Paragraph 9(1)(i.2) - 6ter - National Flag of a Country of the Union'
    }

    GImap = {
        '1' : 'Wine',
        '2' : 'Spirits',
        '3' : 'Agricultural Product or Food'
    }

    def fast_iter(context, func, count, loop, writeobject):
        '''a fast iterating parser script for large XML files, 
        from https://www.ibm.com/developerworks/xml/library/x-hiperfparse/
        as revised in https://stackoverflow.com/questions/7171140/using-python-iterparse-for-large-xml-files/7171543#7171543
        '''
        for event, elem in tqdm(
            context, 
            ncols=100, 
            total = count, 
            desc=f'Parsing collection {loop}',
            unit=' records'
        ): 
            func(elem, writeobject)
            elem.clear() # clears the processed data from memory
            for ancestor in elem.xpath('ancestor-or-self::*'): # clears the root tag of the processed data from memory
                while ancestor.getprevious() is not None:
                    del ancestor.getparent()[0]
        del context # clears the parsed event from memory
    
    def getData(elem, writeobject):
        ''' Pull and process the data for the main.csv file 
        using the tagNeeds XPath dictionary defined above 
        '''
        rowdata = [] # creates a list object to hold parsed data
        
        for field, searchPath in tagNeeds.items():
            if searchPath == False: 
                continue
            else: 
                foundIt = searchPath(elem)
            
                if field == 'Section9Code':
                    if foundIt:    
                        rowdata.append(foundIt[0])
                        rowdata.append(section9map.get(foundIt[0]))
                    else: rowdata = rowdata + ["", ""]
                elif field == 'GICode':
                    if foundIt:
                        rowdata.append(foundIt[0])
                        rowdata.append(GImap.get(foundIt[0]))
                    else: rowdata = rowdata + ["", ""]

                elif foundIt:
                    if field == 'AppNo': rowdata.append(foundIt[0][-9:-2])
                    elif field == 'ExtNo': rowdata.append(foundIt[0][-2:])
                    elif field == 'RegNo': rowdata.append(re.search(r'\d+', foundIt[0]).group())
                    elif foundIt[0] == 'false': rowdata.append(0)
                    elif foundIt[0] == 'true' : rowdata.append(1)
                    elif field in booleanList: rowdata.append(1)
                    else: rowdata.append(' '.join(' '.join(foundIt).split()))
                else:
                    if field in booleanList:
                        rowdata.append(0) # add a zero for indicator variables with no data in this record
                    elif field == 'StanChar':
                        rowdata.append(0)
                    else:
                        rowdata.append('') # add a blank string for non-indicator variables with no data in this record
        # print(rowdata) # un-comment for verbose parsing
        writeobject.writerow(rowdata)

    def countEm(archive):
        '''a counter to determine the number of records in each collection 
        by counting the files in the folder from which the collection was built
        '''
        fileCount = 0
        for foldername in sourceDir.iterdir():
            if foldername.name.endswith(archive):
                for f in foldername.iterdir(): 
                    if f.suffix == '.xml': fileCount += 1
                break
        return fileCount
    
    # set filepath variables

    sourceDir = Path(input('Provide full path of XML_raw folder:'))
    rootDir = sourceDir.parent
    parsePath = rootDir / 'csv' # output path for final execution
    # parsePath = rootDir / 'test' # output path for testing
    print(f'Root Directory: {rootDir.absolute()}')
    print(f'Source Directory: {sourceDir.absolute()}')
    print(f'Target Directory: {parsePath.absolute()}')
    print('Finding XML Collections...')
    parsePath.mkdir(exist_ok=True)
    sourceList = []
        
    # create a container csv file to receive parsed data; 
    # create a CSV output object to pass data to the new file

    with parsePath.joinpath('CA_TM_main.csv').open('w', newline='', encoding='UTF-8')  as newfile:
        fileWriter = csv.writer(newfile, delimiter = '\t')
        
        # assign the dictionary keys to the label row for the CSV file
        headerRow = []
        for labels in tagNeeds.keys(): 
            headerRow.append(labels)
        fileWriter.writerow(headerRow)

        # build the list of xml files for parsing
        for item in sourceDir.iterdir():
            if item.is_file() and item.suffix == '.xml': sourceList.append(item)

        print(f'{len(sourceList)} XML collections found. Parsing...')

        # loop over concatenated XML collections
        for filename in tqdm(
            sourceList, 
            total=len(sourceList), 
            ncols=100, 
            desc='Total Progress', 
            unit='archive',
            position=0, 
            leave=True
        ):
            with sourceDir.joinpath(filename).open('rb') as infile:
                #print(f'\nOpening collection {filename[0:3]}')
                
                #initialize the iterative parser to search for application container tags
                record = etree.iterparse(infile, events=('end',), tag = f'{{http://www.wipo.int/standards/XMLSchema/ST96/Trademark}}TrademarkBag')
                
                # count the number of records to be parsed
                counter = countEm(filename.name[0:3])
                #print(f'{counter} records found.')
                
                #run the parser!
                fast_iter(record, getData, counter, f'{filename.name[0:3]} of {len(sourceList)}', fileWriter)
                #print(f'Parsing of {filename} complete!')
    print(f'Dataset CA_TM_main.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()