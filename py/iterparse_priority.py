#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# A streaming xml parser to extract data for the Canada Trademarks Dataset Priority file.
# To be executed after CIPO-Canada's IP Horizons Trademark Bulk Data has been 
# downloaded and processed using sftp-secure.py

import os
from tqdm import tqdm
import csv
import lxml
from lxml import etree
from pathlib import Path
# import usaddress
# import postal

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
        'AppNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ExtNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityClaim':    etree.XPath('.//tmk:Priority', namespaces = ns_dict, smart_strings=False)
    }

    priorityTags = {
        'PriorityCountry':  etree.XPath('.//com:PriorityCountryCode/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityDocNo':    etree.XPath('.//com:ApplicationNumberText/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityDate':     etree.XPath('.//com:PriorityApplicationFilingDate/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityComment':  etree.XPath('.//com:CommentText/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityClass':    etree.XPath('.//tmk:ClassNumber/text()', namespaces = ns_dict, smart_strings=False),
        'PriorityGoods':    etree.XPath('.//tmk:GoodsServicesDescriptionText/@com:sequenceNumber', namespaces = ns_dict, smart_strings=False)
    }

    # Lay out a label row for the CSV file

    headerRow = [
        'AppNo',
        'ExtNo',
        'PriorityCountry',
        'PriorityDocNo',
        'PriorityDate',
        'PriorityComment',
        'PriorityClass',
        'PriorityGoods'
    ]

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
            func(elem, writeobject, tagDict, stem) # passes the parser context to the data-extraction function
            elem.clear() # clears the processed data from memory
            for ancestor in elem.xpath('ancestor-or-self::*'): # clears everything below the root tag of the processed data from memory
                while ancestor.getprevious() is not None: #clears parent tags of the processed data
                    del ancestor.getparent()[0]
        del context # clears the parsed event from memory

    def getData(elem, writeobject, tagDict, stem = {}):
        ''' Recursively pulls and processes the data for the CA_TM_priority.csv file 
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

        # initialize container for parsed data

        rowdata = stem
        
        # search through the active tag dictionary

        for field, searchPath in tagDict.items():
            
            foundIt = searchPath(elem)

            # pull the Application Number and Serial Number for each Record:
            
            if field == 'AppNo': 
                
                lastlayer = False
                rowdata = {field: foundIt[0][-9:-2]}
            
            elif field == 'ExtNo':
                
                lastlayer = False
                rowdata[field] = foundIt[0][-2:]
                        
            elif field == 'PriorityClaim':
                
                lastlayer = False
                
                for result in foundIt:
                    getData(result, writeobject, tagDict = priorityTags, stem = rowdata)
            
            elif field in priorityTags:
                
                lastlayer = True
                foundIt = searchPath(elem)

                if foundIt:

                    if field == 'PriorityGoods':
                        
                        rowdata[field] = '/'.join(foundIt)

                    else:
                        rowdata[field] = ' '.join(foundIt[0].split())
                
                else:
                    rowdata[field] = ''

        # If there is priority data, write to the CSV file
        
        if lastlayer == True:
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

    with parsePath.joinpath('CA_TM_priority.csv').open('w', newline='', encoding='UTF-8')  as newfile:
        fileWriter = csv.writer(newfile, delimiter = '\t')
        
        # feed in the row of column header labels

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

    print(f'Dataset CA_TM_priority.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()