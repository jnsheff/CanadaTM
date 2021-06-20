#!/usr/bin/env python3

# Original code (c) Jeremy Sheff 2020. Original code published by the author under a CC-BY-4.0 license.
# https://creativecommons.org/licenses/by/4.0/legalcode

# This script prepares the user's python environment to run the installer, 
# then downloads and extracts the 2019 historic trademark applications
# bulk data release from CIPO's IP Horizons SFTP server.
# The user must provide their own SFTP credentials.
# The user may also need to directly connect to the SFTP server 
# via an SFTP client prior to running this script in order to 
# validate the server's SSH certificate on their machine.
# XML parsers can be run on the files extracted and processed  
# by this script to generate research-ready CSV files.

import sys
import subprocess

# implement pip as a subprocess to install needed nonstandard libraries:
print('Installing needed nonstandard python libraries...')
subprocess.check_call([sys.executable, '-m', 'pip', 'install',
'pysftp', 'tqdm', 'lxml', 'regex'])
# process output with an API in the subprocess module:
reqs = subprocess.check_output([sys.executable, '-m', 'pip',
'freeze'])
installed_packages = [r.decode().split('==')[0] for r in reqs.split()]
print(f'\nCurrently installed packages are {installed_packages}\n')

import pysftp
import getpass
from pathlib import Path
import os
from zipfile import ZipFile
from tqdm import tqdm

def main():
    
    # Verify credentials with CIPO SFTP server: 3 strikes and you're out!

    attempts = 0

    while attempts < 3:

        try:
            userID = input('Enter CIPO IP Horizons Username: ')
            userPWD = getpass.getpass(f'Enter password for {userID}: ')
            with pysftp.Connection(
                host='iphorizonspi.opic-cipo.ca', 
                username = userID, 
                password = userPWD
            ) as sftp:
                print("Connection succesfully established ... ")
            break

        except:
            attempts += 1
            if attempts < 3: 
                print(f'Authentication Failed. Attempt {attempts} of 3.')
                continue
            else: 
                print('Authentication failed. Too many failed attempts. Disconnecting.')
                sys.exit()

    #identify local target directory and create local target file
    
    localpath = Path(input('Enter full destination path (NOTE: at least 70GB free disk space needed):'))
    ziplist = localpath / 'zipfilelist.txt'
    
    # Initiate SFTP connection

    with pysftp.Connection(
        host='38.117.69.16', 
        username = userID, 
        password = userPWD
    ) as sftp:
            
        sourceDir = '/dev/cipo-d1/www/clients/client1/web3/web/cipo/client_downloads/Trademarks_Historical_2019_10'
    
        # extract a list of archives and save to local index file

        with ziplist.open('w') as outfile:
            sftp.cwd(sourceDir)
            filetree = sftp.listdir()
            for f in tqdm(
                filetree, 
                total=len(filetree), 
                desc='Extracting file list', 
                ncols=100
            ):
                if f.endswith('.zip') and f.find('Schemas') < 0:
                    print(f, file = outfile)
            print(f'File list saved as {ziplist.absolute()}')

        # create a target local directory to receive downloaded files
        targetDir = localpath / "XML_raw"
        targetDir.mkdir(exist_ok=True)

        # Read in and save list of ZIP archives (zipfilelist.txt)
        with ziplist.open('r') as f:

            # count number of archives to be extracted and initialize counter
            zipCounter = 0
            archiveList = f.readlines()
            zipTotal = len(archiveList)
        
            # Iterate over list of ZIP archives
            for item in tqdm(
                archiveList, 
                desc='Download/Extraction--Total Progress', 
                unit=' archive', 
                total=zipTotal, 
                ncols = 100, 
                position = 1, 
                leave = True
            ):
                
                # Increment archive counter
                zipCounter += 1

                # Identify and Download the ZIP archive from the archive list
                archiveName = item.rstrip()
                archiveStub = archiveName[-7:-4]

                # Find the archive on the SFTP server 
                # and create a local path for its target destination
                zipPath = sourceDir + '/' + archiveName
                tempZip = targetDir / archiveName

                # Get the archive size for the progress bar
                filesize = sftp.lstat(zipPath).st_size

                # Download the archive
                with tqdm(
                    desc=f'Downloading archive {archiveStub}, number {zipCounter} of {zipTotal}', 
                    total = filesize, 
                    unit_scale=True, 
                    ncols=100, 
                    unit='B', 
                    leave=True,
                    position = 2
                ) as pbar:
                    def downloadBar(downloaded, size):
                        pbar.update(downloaded-pbar.n)
                    #The next line is the actual download command
                    sftp.get(remotepath = zipPath, localpath = tempZip, callback=downloadBar)
                
                #Extract XML files (only) from the downloaded ZIP archive
                with ZipFile(tempZip, 'r') as zip: 

                    # create separate destination folders for each ZIP archive's files
                    extractPath = targetDir / Path(archiveName).stem
                    extractPath.mkdir(exist_ok=True)
                    
                    # Generate a list of XML files in the ZIP archive
                    archiveFileList = zip.namelist()
                    for candidate in archiveFileList: 
                        if candidate.endswith('.xml') == False:
                            archiveFileList.remove(candidate)
                    archiveLength = len(archiveFileList)
                    
                    # Iterate over the list of XML files; extract to destination local folder
                    for confirmedXMLFile in tqdm(
                        archiveFileList, 
                        desc=f'Extracting XML records from archive {archiveStub}',
                        total = archiveLength, 
                        ncols = 100, 
                        unit=' files', 
                        leave = True,
                        position = 3
                    ):
                        zip.extract(confirmedXMLFile, path = extractPath)
                   
                    # Delete local copy of ZIP archive (to save disk space; comment out if local copies desired)
                    os.remove(tempZip) 
    
    print(f'\n{zipTotal} archives downloaded and extracted.')
    print('\nDisconnected. SFTP session complete.')
    print('\nProcessing XML records...')

    # Build and count local archive folder list; report result

    zipDirs = []
    for folderName in targetDir.iterdir():
        folderPath = targetDir / folderName
        if folderPath.is_dir():
            zipDirs.append(folderPath)
    
    dirCount = len(zipDirs)
    
    print(f'\nFound {dirCount} archive folders. Concatenating .xml files...') 

    # assign string variables for  XML header and top-level opening and closing tags 
    # to be removed from concatenated files; they'll be added back in once 
    # at the start and end of the concatenated document

    openString = '<?xml version=\"1.0\" encoding=\"UTF-8\"?><tmk:TrademarkApplication xmlns:catmk=\"http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Trademark\" xmlns:ns4=\"http://www.w3.org/1998/Math/MathML\" xmlns:ns3=\"http://www.oasis-open.org/tables/exchange/1.0\" xmlns:com=\"http://www.wipo.int/standards/XMLSchema/ST96/Common\" xmlns:cacom=\"http://www.cipo.ic.gc.ca/standards/XMLSchema/ST96/Common\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:tmk=\"http://www.wipo.int/standards/XMLSchema/ST96/Trademark\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" com:st96Version=\"V3_0\" com:ipoVersion=\"V1_4\">'
    closeString = '</tmk:TrademarkApplication>'

    #loop over archive folders, build list of files in each

    for count, archive in tqdm(
        enumerate(zipDirs), 
        desc = 'XML Processing -- Overall Progress', 
        position = 1, 
        leave = True, 
        ncols=100,
        unit=' archive',
        total=len(zipDirs)
    ):
        archivename = archive.stem[-3:]
        filenames = archive.iterdir()

        # create destination concatenated file
        with targetDir.joinpath(f'{archivename}.xml').open('w') as xmlout:
            # Pass in XML header and top-level open tag
            xmlout.write(openString)
            # loop over XML records in archive and pass text to concatenated file, 
            # removing XML headers and top-level tags
            for fname in tqdm(
                filenames, 
                desc = f'Concatenating Files in archive {archivename} ({count+1} of {dirCount})', 
                ncols = 100,
                unit=' files',
                total = len([f for f in archive.iterdir() if f.is_file() and f.suffix == '.xml']),
                position = 0
            ):
                if fname.is_file() and fname.suffix == '.xml':
                    with fname.open('r') as xmlin:
                        for line in xmlin:
                            xmlout.write(line.replace(openString, '').replace(closeString, ''))
            #add top-level close tag to end of file
            xmlout.write(closeString)

    print('\nCIPO Historical TM Bulk Data has been Downloaded and Processed.')
    print(f'\nIt can be found in the folder {targetDir.absolute()}')

if __name__ == "__main__": main()