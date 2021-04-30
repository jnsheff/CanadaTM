#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# A streaming xml parser to extract data for the Canada Trademarks Dataset International Classes file.
# To be executed after CIPO-Canada's IP Horizons Trademark Bulk Data has been 
# downloaded and processed using sftp-secure.py

import os
from tqdm import tqdm
import csv
import lxml
from lxml import etree
from pathlib import Path

def main():

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
            for ancestor in elem.xpath('ancestor-or-self::*'): # clears everything below the root tag of the processed data from memory
                while ancestor.getprevious() is not None: #clears parent tags of the processed data
                    del ancestor.getparent()[0]
                if ancestor.getprevious() is None: #clears siblings of the processed data
                    for x in ancestor.iterchildren(): del x
        del context # clears the parsed event from memory
    
    def getData(elem, writeobject):
        ''' Pull and process the data for the classes.csv file 
        using the tagNeeds XPath dictionary defined above 
        '''
        # initialize list to capture parsed data and separate list for international classes found
        rowdata = ['' for x in range(1, 48)]
        classificationValues = []
        # extract Class numbers; destring; report results
        for field, searchPath in tagNeeds.items():
            foundIt = searchPath(elem)
            if foundIt:
                if field == 'AppNo': rowdata[0]=foundIt[0][-9:-2]
                elif field == 'ExtNo': rowdata[1]=foundIt[0][-2:]
                elif field == 'Classes':
                    for number in foundIt:
                        classificationValues.append(number)
                        classificationValues = list(map(int, classificationValues)) 
                        for i in range(1, 46):
                            rowdata[i+1]= 1 if i in classificationValues else 0
            else:
                continue
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
    
    # create an xml namespace dictionary for the parser
    
    ns_dict = {
        'catmk' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark",
        'com' : "http://www.wipo.int/standards/XMLSchema/ST96/Common",
        'cacom' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common",
        'tmk' : "http://www.wipo.int/standards/XMLSchema/ST96/Trademark" 
    }

    # Create a dictionary of destination data fields and associated XPath expressions for which data will be extracted
    
    tagNeeds = {
        'AppNo':    etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ExtNo': etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'Classes':  etree.XPath('.//tmk:GoodsServicesClassification/tmk:ClassNumber/text()', namespaces = ns_dict, smart_strings=False)
    }
    
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

    # Create the label row for the CSV file

    headerRow = ['AppNo', 'ExtNo']
    for i in range(1, 46):
        headerRow.append(f'IC{i}')
        
    # create a container csv file to receive parsed data; 
    # create a CSV output object to pass data to the new file; pass it the label row
    with parsePath.joinpath('CA_TM_classes.csv').open('w', newline='', encoding='UTF-8') as newfile:
        fileWriter = csv.writer(newfile, delimiter = '\t')
        fileWriter.writerow(headerRow)
            
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
            unit=' archive'
        ):
            with sourceDir.joinpath(filename).open('rb') as infile:
                #print(f'\nOpening collection {filename[0:3]}')
                
                #initialize the iterative parser to search for application container tags
                record = etree.iterparse(infile, events=('end',), tag = f'{{http://www.wipo.int/standards/XMLSchema/ST96/Trademark}}TrademarkBag')
                
                # count the number of records to be parsed
                counter = countEm(filename.name[0:3])
                            
                #run the parser!

                fast_iter(record, getData, counter, f'{filename.name[0:3]} of {len(sourceList)}', fileWriter)
                #print(f'Parsing of {filename} complete!')
    print(f'Dataset CA_TM_classes.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()