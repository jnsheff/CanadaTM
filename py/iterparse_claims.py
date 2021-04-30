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
import itertools

def main():

### namespace map for the xml parser
    ns_dict = {
        'catmk' :   "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark",
        'com' :     "http://www.wipo.int/standards/XMLSchema/ST96/Common",
        'cacom' :   "http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common",
        'tmk' :     "http://www.wipo.int/standards/XMLSchema/ST96/Trademark" 
    }
      
### Dictionaries of a series of fields for the parser to search at various levels of the XML hierarchy
    
    tagNeeds = {
        'AppNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ExtNo':            etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'Claim':            etree.XPath('.//catmk:Claim', namespaces = ns_dict, smart_strings=False)     
    }

    claimTags = {
        'ClaimTypeCode':    etree.XPath('.//catmk:ClaimCategoryType/text()', namespaces = ns_dict, smart_strings=False),
        'ClaimTypeDesc':    etree.XPath('.//catmk:ClaimTypeDescription/text()', namespaces = ns_dict, smart_strings=False),
        'ClaimSerialNo':    etree.XPath('.//catmk:ClaimNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ClaimCode':        etree.XPath('.//catmk:ClaimCode/text()', namespaces = ns_dict, smart_strings=False),
        'ClaimDesc':        etree.XPath('.//catmk:ClaimText/text()', namespaces = ns_dict, smart_strings=False),
        'Country':          etree.XPath('.//catmk:ClaimCountryCode/text()', namespaces = ns_dict, smart_strings=False),
        'ForeignDocNo':     etree.XPath('.//catmk:ClaimForeignRegistrationNbr/text()', namespaces = ns_dict, smart_strings=False),
        'ClaimedGoods':     etree.XPath('.//catmk:GoodsServicesReferenceIdentifier/text()', namespaces = ns_dict, smart_strings=False),
        'CompleteDate':     etree.XPath('.//catmk:StructuredClaimDate/text()', namespaces = ns_dict, smart_strings=False),
        'PartialDate':      etree.XPath('.//catmk:UnstructuredClaimDate', namespaces = ns_dict, smart_strings=False) 
    }

    dateTags = {
        'Year':     etree.XPath('.//catmk:ClaimYear/text()', namespaces = ns_dict, smart_strings=False),
        'Month':    etree.XPath('.//catmk:ClaimMonth/text()', namespaces = ns_dict, smart_strings=False),
        'Day':      etree.XPath('.//catmk:ClaimDay/text()', namespaces = ns_dict, smart_strings=False)
    }

    recursives = {
        'Claim': claimTags,
        'PartialDate': dateTags
    }

    textFields = [
        'ClaimTypeCode',
        'ClaimTypeDesc',
        'ClaimSerialNo',
        'ClaimCode',
        'ClaimDesc',
        'CompleteDate',
        'Country',
        'ForeignDocNo',
        'ClaimedGoods',
        'Year',
        'Month',
        'Day',
        'CompleteDate'
    ]

    #create dictionaries for codes set forth in line 453 of data spec
    
    claim10Codes = {
        '1': 'Date of Making Known in Canada',
        '2': 'Made Known in Canada since',
        '3': 'Made Known in Canada since at least as early as',
        '4': 'Made Known in Canada since as early as',
        '5': 'Made Known in Canada since at least',
        '6': 'entire text',
        '7': 'Made Known in Canada since before'
    }

    claim11Codes = {
        '1': 'Used in Canada since',
        '2': 'Used in Canada since at least as early as',
        '3': 'Used in Canada since at least',
        '4': 'Used in Canada since as early as',
        '5': 'Date of first use in Canada',
        '6': 'entire text',
        '7': 'Used in Canada since before'
    }

    claim17Codes = {
        '1': 'Registrability Recognized under Section 14 of the Trade-marks Act',
        '2': 'Registrability Recognized under Section 12(2) of the Trade-marks Act',
        '3': 'Registration is subject to the provisions of Section 67(1) of the Trade-marks Act, in view of Newfoundland Registration No.',
        '4': 'Entire text',
        '5': 'Registrability Recognized under Rule 10 of the Trade Mark and Design Act',
        '6': 'Registrability Recognized under Section 28(1)(d) of the Unfair Competition Act',
        '7': 'Benefit of Section 14 of the Trade-marks Act is claimed'
    }

    claimCodeMap = {
        '10': claim10Codes,
        '11': claim11Codes,
        '17': claim17Codes
    }
    
    # Lay out a label row for the CSV file

    headerRow = [
        'AppNo',
        'ExtNo',
        'ClaimTypeCode',
        'ClaimTypeDesc',
        'ClaimSerialNo',
        'ClaimCode',
        'ClaimDesc',
        'Year',
        'Month',
        'Date',
        'Country',
        'ForeignDocNo',
        'ClaimedGoods'
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
        ''' Recursively pulls and processes the data for the CA_TM_claims.csv file 
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
                rowdata = {field: searchPath(elem)[0][-9:-2]}
            
            elif field == 'ExtNo':
                
                lastlayer = False
                rowdata[field] = searchPath(elem)[0][-2:]
                        
            # recursively search fields that have sub-fields of interest
            # by parsing them as separate etree elements and feeding them 
            # back into the fast_iter function, adding relevant data for each field found
             
            elif field in recursives.keys():
                
                if field == 'PartialDate':
                    if foundIt:
                        lastlayer = False
                        for result in foundIt:
                            getData(result, writeobject, tagDict = recursives.get(field), stem = rowdata)
                    else: 
                        lastlayer = True
                else:
                    for result in foundIt:
                        getData(result, writeobject, tagDict = recursives.get(field), stem = rowdata)  

            elif field in textFields:
                lastlayer = True
                rowdata[field] = ''
                foundIt = searchPath(elem)
                if foundIt:
                    if field == 'CompleteDate':
                        datestring = str(foundIt[0])
                        rowdata['Year'] = datestring[0:4]
                        rowdata['Month'] = datestring[5:7]
                        rowdata['Date'] = datestring[-2:]
                        break
                    elif field == 'Month': # ensures leading zeros are captured by storing as string
                        rowdata[field] = str(foundIt[0])
                    elif field == 'ClaimDesc':
                        rowdata[field] = ' '.join(foundIt[0].split())
                    elif field == 'ClaimedGoods':
                        rowdata[field] = '/'.join(foundIt)
                    else:
                        rowdata[field] = foundIt[0]
                else: 
                    if field == 'Year' or 'Month' or 'Date':
                        continue
                    else:
                        rowdata[field] = ''

        # When there are no further recursive loops, write to the CSV file
        
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

    with parsePath.joinpath('CA_TM_claims.csv').open('w', newline='', encoding='UTF-8')  as newfile:
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

    print(f'Dataset CA_TM_claims.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()