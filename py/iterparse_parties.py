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
        'AppNo':        etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ExtNo':     etree.XPath('.//tmk:Trademark/com:ApplicationNumber/com:ST13ApplicationNumber/text()', namespaces = ns_dict, smart_strings=False),
        'ApplicantBag': etree.XPath('.//tmk:Applicant', namespaces = ns_dict, smart_strings=False),
        'RepBag':       etree.XPath('.//tmk:NationalRepresentative', namespaces = ns_dict, smart_strings=False),
        'OppBag':       etree.XPath('.//tmk:OppositionProceedingBag', namespaces = ns_dict, smart_strings=False),
        'CancelBag':    etree.XPath('.//tmk:CancellationProceedings', namespaces = ns_dict, smart_strings=False),
        'Interested':   etree.XPath('.//catmk:InterestedParty', namespaces = ns_dict, smart_strings=False)
    }

    # Second-Level Tags:

    oppTags = {
        'ProceedingType':   etree.XPath('.//catmk:OppositionCaseTypeDescription[@com:languageCode="en"]/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingSeq':    etree.XPath('.//com:OppositionIdentifier/text()', namespaces=ns_dict, smart_strings=False),
        'Plaintiff':        etree.XPath('.//tmk:Plaintiff', namespaces = ns_dict, smart_strings=False),
        'Defendant':        etree.XPath('.//tmk:Defendant', namespaces = ns_dict, smart_strings=False)
    }

    cancelTags = {
        'ProceedingType':   etree.XPath('.//catmk:OppositionCaseTypeDescription[@com:languageCode="en"]/text()', namespaces=ns_dict, smart_strings=False),
        'ProceedingSeq':    etree.XPath('.//tmk:LegalProceedingIdentifier/text()', namespaces=ns_dict, smart_strings=False),
        'Plaintiff':        etree.XPath('.//tmk:Plaintiff', namespaces = ns_dict, smart_strings=False),
        'Defendant':        etree.XPath('.//tmk:Defendant', namespaces = ns_dict, smart_strings=False)
    }

    # Deepest-level Tags
    
    partyTags = {
        'PartyName':        etree.XPath('./com:Contact/com:Name/com:EntityName/text()', namespaces=ns_dict, smart_strings=False),
        'AgentCode':        etree.XPath('./com:CommentText/text()', namespaces=ns_dict, smart_strings=False),
        'Address':          etree.XPath('./com:Contact/com:PostalAddressBag//com:AddressLineText/text()|./com:Contact/com:PostalAddressBag//com:AddressLineText/text()', namespaces=ns_dict, smart_strings=False),
        'Province':         etree.XPath('./com:Contact/com:PostalAddressBag//com:GeographicRegionName/text()', namespaces=ns_dict, smart_strings=False),
        'Country':          etree.XPath('./com:Contact/com:PostalAddressBag//com:CountryCode/text()', namespaces=ns_dict, smart_strings=False),
        'PostCode':         etree.XPath('./com:Contact/com:PostalAddressBag//com:PostalCode/text()', namespaces=ns_dict, smart_strings=False)
    }
   
    interestedTags = {'PartyType':   etree.XPath('.//catmk:InterestedPartyCategory/text()', namespaces=ns_dict, smart_strings=False)}
    interestedTags.update(partyTags)

    repTags = partyTags
    repTags['Representative'] = etree.XPath('.//com:Representative', namespaces=ns_dict, smart_strings=False)
    

    # Address fields: to be cleared for recursive parsing of Representatives

    postalTags = {
        
        'Address':  etree.XPath('.//com:AddressLineText/text()|.//com:PostalAddressText/text()', namespaces=ns_dict, smart_strings=False),
        'Province': etree.XPath('.//com:GeographicRegionName/text()', namespaces=ns_dict, smart_strings=False),
        'Country':  etree.XPath('.//com:CountryCode/text()', namespaces=ns_dict, smart_strings=False),
        'PostCode': etree.XPath('.//com:PostalCode/text()', namespaces=ns_dict, smart_strings=False)
    }
    
    # a list of fields for which no further recursive searching will be needed:

    textFields = [
        'ProceedingType',
        'ProceedingSeq',
        'PartyType', 
        'PartyName',
        'AgentCode',
        'Address',
        'Province',
        'Country',
        'PostCode'
    ]

    # a dictionary of fields that trigger a recursive search one level down the hierarchy,  
    # mapped to the dictionary of fields to be searched within the recursive loop

    recursives = {
        'ApplicantBag':     partyTags,
        'RepBag':           partyTags,
        'OppBag':           oppTags,
        'CancelBag':        cancelTags,
        'Plaintiff':        repTags,
        'Defendant':        repTags,
        'Representative':   partyTags,
        'Interested':       interestedTags
    }

    # Lay out a label row for the CSV file

    headerRow = [
        'AppNo',
        'ExtNo',
        'PartyType',
        'AgentCode',
        'ProceedingType',
        'ProceedingSeq',
        'PartyName',
        'Address',
        'Province',
        'Country',
        'PostCode'
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
        ''' Recursively pulls and processes the data for the CA_TM_parties.csv file 
        from the iterparse/iterwalk context using the dictionaries of tags of interest
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
            # back into the getData function, adding relevant data for each field found
             
            elif field in recursives.keys():
                
                lastlayer = False
                
                if field == 'ApplicantBag':
                    rowdata['PartyType'] = 'Current Owner'
                elif field == 'RepBag':
                    rowdata['PartyType'] = 'Current Owner\'s Representative'
                elif field == 'Plaintiff':
                    rowdata['PartyType'] = 'Plaintiff'
                elif field == 'Defendant':
                    rowdata['PartyType'] = 'Defendant'
                elif field == 'Representative':
                    # Output the Plaintiff or Defendant data prior to searching for their Attorney's data
                    printIt(rowdata)
                    # 
                    rowdata['PartyType'] = rowdata.get('PartyType') + '\'s Representative'
                    for tag in rowdata.keys():
                        # Clear any party address data to make way for their attorney's address data
                        if tag in postalTags.keys(): rowdata[tag] = False
                elif field == 'Interested':
                    # The Interested Party tag occurs after proceeding tags in the XML hierarchy;
                    # Any proceedings data needs to be purged to make way for Interested Party data
                    rowdata['ProceedingType'] = False
                    rowdata['ProceedingSeq'] = False
                
                for result in foundIt:
                    getData(result, writeobject, tagDict = recursives.get(field), stem = rowdata)                

            elif field in textFields:
                lastlayer = True
                foundIt = searchPath(elem)
                if foundIt:
                    if field == 'Address' or 'PartyName':
                        # merge multi-line/multi-element tags into a single string
                        rowdata[field] = (' '.join(' '.join(foundIt).split()))
                    else: 
                        for value in foundIt:
                            rowdata[field] = value
                else: 
                    rowdata[field] = False

        # When there are no further recursive loops, write to the CSV file
        
        if lastlayer == True: printIt(rowdata)

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

    with parsePath.joinpath('CA_TM_parties.csv').open('w', newline='', encoding='UTF-8')  as newfile:
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

    print(f'Dataset CA_TM_parties.csv is now available in folder {parsePath.absolute()}')
   
if __name__ == "__main__": main()