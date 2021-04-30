#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# A streaming xml parser to extract data for the Canada Trademarks Dataset Proceedings and Events file.
# To be executed after CIPO-Canada's IP Horizons Trademark Bulk Data has been 
# downloaded and processed using sftp-secure.py

import os
from tqdm import tqdm
import csv
import lxml
from lxml import etree
from pathlib import Path

def main():

### namespace map for the xml parser
    ns_dict = {
        'catmk' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark",
        'com' : "http://www.wipo.int/standards/XMLSchema/ST96/Common",
        'cacom' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common",
        'tmk' : "http://www.wipo.int/standards/XMLSchema/ST96/Trademark" 
    }
      
### Dictionaries of a series of fields for the parser to search at various levels of the XML hierarchy

    # Root-level Tags:

    tagNeeds = {
        'AppNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces=ns_dict, smart_strings=False),
        'ExtNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces=ns_dict, smart_strings=False),
        'EventBag':         etree.XPath('.//tmk:MarkEvent', namespaces=ns_dict, smart_strings=False),
        'FootnoteBag':      etree.XPath('.//catmk:Footnote', namespaces=ns_dict, smart_strings=False),
        'CancelBag':        etree.XPath('.//tmk:CancellationProceedings', namespaces=ns_dict, smart_strings=False),  
        'OppBag':           etree.XPath('.//tmk:OppositionProceedingBag', namespaces=ns_dict, smart_strings=False)
    }

    # Tags to search within the OppositionProceedingBag Tag, one level down from root:

    FootnoteTags = {
        'EventCode':        etree.XPath('.//cacom:CategoryCode/text()', namespaces=ns_dict, smart_strings=False),
        'EventDesc':        etree.XPath('.//cacom:CategoryDescription/text()', namespaces=ns_dict, smart_strings=False),
        'FilingDate':       etree.XPath('.//cacom:RegisteredDate/text()', namespaces=ns_dict, smart_strings=False),
        'EventDate':        etree.XPath('.//cacom:ChangedDate/text()', namespaces=ns_dict, smart_strings=False)
    }
    
    OppTags = {
        'EventType':        etree.XPath('.//catmk:OppositionCaseTypeDescription[@com:languageCode="en"]/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingSeq':    etree.XPath('.//com:OppositionIdentifier/text()', namespaces=ns_dict, smart_strings=False),
        'FilingDate':       etree.XPath('.//com:OppositionDate/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingStage':  etree.XPath('.//catmk:ProceedingStage', namespaces=ns_dict, smart_strings=False)
    }

    # Tags to search within the CancellationProceedings Tag, one level down from root
    # (note: the CIPO data dictionary has some mistakes here)

    CancelTags = {
        'EventType':        etree.XPath('.//catmk:OppositionCaseTypeDescription[@com:languageCode="en"]/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingSeq':    etree.XPath('.//tmk:LegalProceedingIdentifier/text()', namespaces=ns_dict, smart_strings=False),
        'FilingDate':       etree.XPath('.//tmk:LegalProceedingFilingDate/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingStage':  etree.XPath('.//catmk:ProceedingStage', namespaces=ns_dict, smart_strings=False)

    }

    # Proceeding Stage tags: two levels down from root, within the Opposition or Cancellation bags
    
    stageTags = {
        'StageCode':        etree.XPath('.//catmk:ProceedingStageCode/text()', namespaces=ns_dict, smart_strings=False),
        'StageDesc':        etree.XPath('.//catmk:ProceedingStageDescriptionText[@com:languageCode="en"]/text()',namespaces=ns_dict, smart_strings=False),
        'StageEvents':      etree.XPath('.//tmk:ProceedingEvent', namespaces=ns_dict, smart_strings=False)
    }

    # Event data: Either lifecycle events one level down from root 
    # or proceeding events three levels down from root
    
    eventTags = {
        'EventCode':        etree.XPath('.//tmk:MarkEventCode/text()', namespaces=ns_dict, smart_strings=False),
        'EventDesc':        etree.XPath('.//tmk:MarkEventDescriptionText/text()', namespaces=ns_dict, smart_strings=False),
        'EventDate':        etree.XPath('.//tmk:MarkEventDate/text()', namespaces=ns_dict, smart_strings=False)
    }
    
    # a list of fields for which no further recursive searching will be needed:

    textFields = [
        'EventType',
        'ProceedingSeq', 
        'FilingDate', 
        'StageCode',
        'StageDesc',
        'EventCode',
        'EventDesc',
        'EventDate'
    ]

    # a dictionary of fields that trigger a recursive search one level down the hierarchy,  
    # mapped to the dictionary of fields to be searched within the recursive loop

    recursives = {
        'OppBag':           OppTags,
        'CancelBag':        CancelTags,
        'ProceedingStage':  stageTags,
        'StageEvents':      eventTags
    }

    def fast_iter(context, func, writeobject, count=0, loop='Parsing', tagDict = {}, stem = {}, quiet = False):
        '''a fast iterating parser script for large XML files, 
        from https://www.ibm.com/developerworks/xml/library/x-hiperfparse/
        as revised in https://stackoverflow.com/questions/7171140/using-python-iterparse-for-large-xml-files/7171543#7171543
        '''
        for event, elem in tqdm( # initializes the progress bar 
            context, 
            ncols=100, 
            total = count, 
            desc=f'Parsing collection {loop}',
            unit=' records',
            disable = quiet
        ): 
            func(elem, writeobject, tagDict, stem) # passes the parser context, the search fields, and any already-parsed data to the data-extraction function
            elem.clear() # clears the processed data from memory after parsing
            for ancestor in elem.xpath('ancestor-or-self::*'): # clears everything below the root tag of the processed data from memory
                while ancestor.getprevious() is not None: 
                    del ancestor.getparent()[0]
        del context # clears the parsed event from memory

    def getData(elem, writeobject, tagDict, stem = {}):
        ''' Recursively pulls and processes the data for the CA_TM_allevents.csv file 
        from the iterparse context using the dictionaries of tags of interest
        '''
        def printIt(rowdata, writeobject = writeobject, headerRow = headerRow, stem = stem):
            thisRow = []
            for field in headerRow:
                foundData = rowdata.get(field)
                if foundData:
                    thisRow.append(foundData)
                else: thisRow.append('')
            writeobject.writerow(thisRow)

        # create boolean variable to determine whether further recursion is needed
        lastlayer = True

        # initialize containers for parsed data
        rowdata = stem
        
        # search through the active tag dictionary

        for field, searchPath in tagDict.items():
            
            foundIt = searchPath(elem)

            # pull the Application Number and Serial Number for each Record:
            
            if field == 'AppNo': 
                
                lastlayer = False
                rowdata = {field: searchPath(elem)[0][-9:-2]}
            
            elif field == 'ExtNo':
                
                lastlayer = False
                rowdata[field] = searchPath(elem)[0][-2:]
                
            # for non-adversarial events: populate unneeded fields with blank strings
            # before recursively searching for event data:
            
            elif field == 'FootnoteBag':
                
                lastlayer = False
                rowdata['EventType'] = "Amendment"
                for i in range(3, 6):
                    rowdata[i] = ''

                for result in foundIt:
                    getData(result, writeobject, tagDict = FootnoteTags, stem = rowdata)

            # for footnote (registration amendment) events: populate unneeded fields with blank strings
            # before recursively searching for event data:
            elif field == 'EventBag':
                
                lastlayer = False
                rowdata['EventType'] = 'Office Action'
                for i in range(3, 6):
                    rowdata[i] = ''
                
                # Build an iterative parser object from the current element; 
                # pass it back into the parser function:

                for result in foundIt:
                    getData(result, writeobject, tagDict = eventTags, stem = rowdata)

            # pull text fields for each record at the current level of the XML hierarchy
            
            elif field in textFields:
                if foundIt:
                    for result in foundIt:
                        # keep running value for event date 
                        # to fill empty date fields per CIPO definitions
                        if field == 'EventDate':
                            if foundIt: currentDate = result
                            else: 
                                if rowdata['EventType'] == 'Amendment':
                                    rowdata['EventDate'] = rowdata['FilingDate']
                                else:
                                    result = currentDate
                        rowdata[field] = result
                else: 
                    rowdata[field] = ''

            # recursively search fields that have sub-fields of interest
            # by parsing them as separate etree elements and feeding them 
            # back into the fast_iter function

            elif field in recursives.keys():
                lastlayer = False
                
                if foundIt:
                    for result in foundIt:
                        getData(result, writeobject, tagDict = recursives.get(field), stem = rowdata)

        # When there are no further recursive loops, check for event data
        # If present, write to the CSV file
        if lastlayer == True and len(rowdata) > 2:
            
            printIt(rowdata)

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
    
    # set filepath variables; create a CSV file to receive parsed data

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

    with parsePath.joinpath('CA_TM_allevents.csv').open('w', newline='', encoding='UTF-8')  as newfile:
        fileWriter = csv.writer(newfile, delimiter = '\t')
        
    # Create a label row for the CSV file; pass it to the new file
    
        headerRow = [
            'AppNo',
            'ExtNo',
            'EventType',
            'ProceedingSeq',
            'FilingDate',
            'StageCode',
            'StageDesc',
            'EventCode', 
            'EventDesc', 
            'EventDate'
        ]

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
            position=0, 
            leave=True,
            unit='archive'
        ):
            with sourceDir.joinpath(filename).open('rb') as infile:
                            
                #initialize the iterative parser to search for application container tags
                record = etree.iterparse(infile, events = ('end',), tag = (f'{{http://www.wipo.int/standards/XMLSchema/ST96/Trademark}}TrademarkBag'))
                
                # count the number of records to be parsed
                counter = countEm(filename.name[0:3])
                
                #run the parser!
                
                fast_iter(record, getData, fileWriter, counter, f'{filename.name[0:3]} of {len(sourceList)}', tagNeeds, quiet = False)
                
    print(f'Dataset CA_TM_allevents.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()