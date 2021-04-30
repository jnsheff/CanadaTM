#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# A streaming xml parser to extract data for the Canada Trademarks Dataset Goods and Services file.
# To be executed after CIPO-Canada's IP Horizons Trademark Bulk Data has been 
# downloaded and processed using sftp-secure.py

import os
from tqdm import tqdm
import csv
import lxml
from lxml import etree
from pathlib import Path
import itertools

def main():

    global maxLength 
    
    maxLength = 0

    # create an xml namespace dictionary for the parser
    
    ns_dict = {
        'catmk' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark",
        'com' : "http://www.wipo.int/standards/XMLSchema/ST96/Common",
        'cacom' : "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common",
        'tmk' : "http://www.wipo.int/standards/XMLSchema/ST96/Trademark" 
    }

    # Create a dictionary of destination data fields and associated XPath expressions for which data will be extracted
    
    tagNeeds = {
        'AppNo':        etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces=ns_dict, smart_strings=False),
        'ExtNo':     etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces=ns_dict, smart_strings=False),
        'GoodsClass':   etree.XPath('.//tmk:GoodsServicesBag//tmk:ClassDescription/tmk:ClassNumber/text()', namespaces=ns_dict, smart_strings=False),
        'GoodsSeq':     etree.XPath('.//tmk:GoodsServicesBag//tmk:GoodsServicesDescriptionText/@com:sequenceNumber', namespaces=ns_dict, smart_strings=False),
        'GoodsDesc':    etree.XPath('.//tmk:GoodsServicesBag//tmk:GoodsServicesDescriptionText/text()', namespaces=ns_dict, smart_strings=False)
    }
    
    def fast_iter(context, func, writeobject, count, loop):
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
        # initialize lists to capture parsed data
        rowdata = []
        classes = []
        goodsLabels = []
        goodsDesc = []
        
        # extract application number and goods data; organize into sequences, write to csv file
        for field, searchPath in tagNeeds.items():
            foundIt = searchPath(elem)
            if foundIt:
                if field == 'AppNo': 
                    rowdata.append(foundIt[0][-9:-2])
                elif field == 'ExtNo': 
                    rowdata.append(foundIt[0][-2:])
                elif field == 'GoodsClass': 
                    classes = foundIt
                elif field == 'GoodsSeq': 
                    goodsLabels = foundIt
                elif field == 'GoodsDesc': 
                    goodsDesc = foundIt
                    # merge multi-line/multi-element descriptions into a single string
                    for item in goodsDesc:
                        newItem = ' '.join(item.split())
                        i = foundIt.index(item)
                        foundIt[i] = newItem
            else:
                continue
        
        goodsList = itertools.zip_longest(classes, goodsLabels, goodsDesc, fillvalue = '')
        if goodsList:
            for sequence in goodsList:
                thisrow = rowdata + list(sequence)
                writeobject.writerow(thisrow)

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
            
    for item in sourceDir.iterdir():
        if item.is_file() and item.suffix == '.xml': sourceList.append(item)
    print(f'{len(sourceList)} XML collections found. Parsing...')

    # create a container csv file to receive parsed data; 
    # create a CSV output object to pass data to the new file; pass it the label row
    with parsePath.joinpath('CA_TM_goods.csv').open('w', newline='', encoding='UTF-8') as newfile:
        # Create the label row for the CSV file
        headerRow = ['AppNo', 'ExtNo', 'Class', 'GoodsSeq', 'GoodsDesc']
        fileWriter = csv.writer(newfile, delimiter = '\t')
        fileWriter.writerow(headerRow)
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
                
                #initialize the iterative parser to search for application container tags
                record = etree.iterparse(infile, events=('end',), tag = f'{{http://www.wipo.int/standards/XMLSchema/ST96/Trademark}}TrademarkBag')
                
                # count the number of records to be parsed
                counter = countEm(filename.name[0:3])
                
                #run the parser!
                
                fast_iter(record, getData, fileWriter, counter, f'{filename.name[0:3]} of {len(sourceList)}')
        
    print(f'Dataset CA_TM_goods.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()