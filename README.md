# CanadaTM
The Canada Trademarks Dataset

18 Journal of Empirical Legal Studies (forthcoming 2021), available at https://papers.ssrn.com/abstract=3782655

Dataset Selection and Arrangement (c) 2021 Jeremy Sheff

Python and Stata Scripts (c) 2021 Jeremy Sheff

Contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office. 

### VERSION 2.0: JANUARY 2023 UPDATES ###

The January 2023 update brings the Canada Trademarks Dataset up to date with weekly application data published by CIPO through January 24, 2023, and includes a total of 1,916,950 application records. The python scripts for constructing the dataset have been rewritten to allow for regular updates with new weekly application data. The new versions of these scripts require access to a mySQL server to store and update the data. Those who simply wish to use the current dataset rather than keep it updated on their own can simply download the .csv and/or .dta files included in this distribution.

Details of Repository Contents:

This repository includes a number of .zip archives which expand into folders containing either scripts for construction of the dataset or data files comprising the dataset itself. These folders are as follows:

- /csv: contains the .csv versions of the version 2.0 data files, current through January 24, 2023
- /dta: contains the .dta versions of the version 2.0 data files, current through January 24, 2023
- /py: contains the python scripts used to construct and update the version 2.0 dataset

The repository also contains 2 additional files:

- CA_TM_mysql_2023-01-24.sql: this is the mySQL database dump for the Version 2.0 dataset, current through January 24, 2023
- CA_TM_csv_cleanup_2023.do: this Stata do-file will convert .csv files generated by the python installation scripts into .dta files. Users should perform a search-and-replace on the partial path "/mypath" to direct the script to the appropriate local directory before running the do-file.

If users wish to construct rather than download the Version 2.0 datafiles, they should run the script /py/CA_TM.py. This script will prompt the user to enter their IP Horizons SFTP credentials; these can be obtained by registering with CIPO at https://ised-isde.survey-sondage.ca/f/s.aspx?s=59f3b3a4-2fb5-49a4-b064-645a5e3a752d&lang=EN&ds=SFTP. Users may need to log in to this server with an SFTP client prior to running the script in order to validate the server's SSH certificate on their machine. The script will also prompt the user to enter their mySQL database credentials and identify a local directory for the data downloads and output files. Because the data archives are quite large, users are advised to create a target directory in advance and ensure they have at least 200GB of available storage on the media in which the directory is located.

The CA_TM.py script can also be used to check for new weekly updates at CIPO, download them, add them to the mySQL database, and generate new .csv files. Users will be prompted to select either a clean install of the complete dataset (including the historical snapshot) or an update of their existing installation. Once the mySQL database is created and the historical snapshot is processed, users may run this script as often as they like to keep their installation of the dataset current with CIPO's weekly releases.

Users who wish to regularly update their installation of the dataset may instead wish to install the mySQL database dump included in this release and run CA_TM.py periodically to keep it current. To do so, they may download the database dump included in the Version 2.0 repository and use the mysql command from their command line to copy it to their mySQL instance:

    mysql --host=[yourhost] --user=[username] -p[password] --port=3306 CA_TM < [path_to_file]/CA_TM_mysql_2023-01-24.sql

Users who update their dataset frequently may wish to edit the config.py script to hard-code their SFTP and mySQL credentials and their local file path, and to remove or comment out the commands to install nonstandard python libraries after the first installation. Such users should also be aware that the update script begins by backing up the existing mySQL database in the "/mysql_backups" folder; users who do not require backups may wish to remove these files to save space once they have confirmed that their update was successful. Such users should also take care not to delete or modify the files generated by the update script to keep track of which weekly CIPO update files have already been incorporated into their installation of the dataset. These are:

- XML_updates/allarchives.txt
- XML_updates/downloadedupdates.txt
- XML_updates/updatestobeconcatenated.txt
- XML_updates/updatestobeparsed.txt

Additional terms of use are set forth in the release notes for Version 1.0.

### VERSION 1.0 RELEASE NOTES ###

This individual-application-level dataset includes records of all applications for registered trademarks in Canada since approximately 1980, and of many preserved applications and registrations dating back to the beginning of Canada’s trademark registry in 1865, totaling over 1.6 million application records. It includes comprehensive bibliographic and lifecycle data; trademark characteristics; goods and services claims; identification of applicants, attorneys, and other interested parties (including address data); detailed prosecution history event data; and data on application, registration, and use claims in countries other than Canada. The dataset has been constructed from public records made available by the Canadian Intellectual Property Office. Both the dataset and the code used to build and analyze it are presented for public use on open-access terms.

Scripts are licensed for reuse subject to the Creative Commons Attribution License 4.0 (CC-BY-4.0), https://creativecommons.org/licenses/by/4.0/. Data files are licensed for reuse subject to the Creative Commons Attribution License 4.0 (CC-BY-4.0), https://creativecommons.org/licenses/by/4.0/, and also subject to additional conditions imposed by the Canadian Intellectual Property Office (CIPO) as described below.

TERMS OF USE:

As per the terms of use of CIPO's government data, all users are required to include the above-quoted attribution to CIPO in any reproductions of this dataset. They are further required to cease using any record within the datasets that has been modified by CIPO and for which CIPO has issued a notice on its website in accordance with its Terms and Conditions, and to use the datasets in compliance with applicable laws. These requirements are in addition to the terms of the CC-BY-4.0 license, which require attribution to the author (among other terms). For further information on CIPO’s terms and conditions, see https://www.ic.gc.ca/eic/site/cipointernet-internetopic.nsf/eng/wr01935.html. For further information on the CC-BY-4.0 license, see https://creativecommons.org/licenses/by/4.0/.

The following attribution statement, if included by users of this dataset, is satisfactory to the author, but the author makes no representations as to whether it may be satisfactory to CIPO:

**The Canada Trademarks Dataset is (c) 2021 by Jeremy Sheff and licensed under a CC-BY-4.0 license, subject to additional terms imposed by the Canadian Intellectual Property Office. It contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office. For further information, see https://creativecommons.org/licenses/by/4.0/ and https://www.ic.gc.ca/eic/site/cipointernet-internetopic.nsf/eng/wr01935.html.**

DETAILS OF PROJECT CONTENTS:

This project includes python scripts that can be used to download the CIPO IP Horizons historical trademarks data via SFTP and construct the csv data files comprising the Canada Trademarks Dataset described in the above-cited paper and archived on Zenodo (https://doi.org/10.5281/zenodo.4999655). These scripts are licensed for reuse subject to the terms of the CC-BY-4.0 license, and users are invited to adapt the scripts to their needs. These scripts require the user to obtain SFTP credentials from CIPO using the registration link provided at https://ised-isde.survey-sondage.ca/f/s.aspx?s=59f3b3a4-2fb5-49a4-b064-645a5e3a752d&lang=EN&ds=SFTP. They also require storage media with at least 70GB of free space. The python scripts can be found in the "py" folder within this repository.

This project also includes Stata do-files used to convert the csv data files to .dta format and conduct the analyses set forth in the above-cited paper describing the dataset. These do-files are also licensed for reuse subject to the terms of the CC-BY-4.0 license, and users are invited to adapt the scripts to their needs.  The do-files can be found in the "do" folder within this repository.

If users wish to construct the dataset themselves rather than download it from the Zenodo repository, **the first script that users should run is /py/sftp_secure.py.** This script will prompt the user to enter their IP Horizons SFTP credentials; as noted above these can be obtained by registering with CIPO at https://ised-isde.survey-sondage.ca/f/s.aspx?s=59f3b3a4-2fb5-49a4-b064-645a5e3a752d&lang=EN&ds=SFTP. The script will also prompt the user to identify a target directory for the data downloads. Because the data archives are quite large, users are advised to create a target directory in advance and ensure they have at least 70GB of available storage on the media in which the directory is located.

The sftp_secure.py script will generate a new subfolder in the user’s target directory called **/XML_raw**. Users should note the full path of this directory, which they will be prompted to provide when running the remaining python scripts. Each of the remaining scripts in the /py directory, the filenames of which begin with **“iterparse”**, corresponds to one of the data files in the dataset, as indicated in the script’s filename. After running one of these scripts, the user’s target directory should include a /csv subdirectory containing the data file corresponding to the script; after running all the iterparse scripts the user’s /csv directory should be identical to the /csv directory available via the Zenodo repository.

With respect to the Stata do-files, only one of them is relevant to construction of the dataset itself. This is **/do/CA_TM_csv_cleanup.do**, which converts the .csv versions of the data files to .dta format, and uses Stata’s labeling functionality to reduce the size of the resulting files while preserving information. The other do-files generate the analyses and graphics presented in the accompanying paper (https://papers.ssrn.com/abstract=3782655).
