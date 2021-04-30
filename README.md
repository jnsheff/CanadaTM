# CanadaTM
The Canada Trademarks Dataset

Selection and Arrangement (c) 2021 Jeremy Sheff

Python and Stata Scripts (c) 2021 Jeremy Sheff

Contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office. 

Data files and scripts are licensed for reuse subject to the Creative Commons Attribution License 4.0 (CC-BY-4.0), https://creativecommons.org/licenses/by/4.0/, subject to additional conditions imposed by the Canadian Intellectual Property Office (CIPO) as described below.

ATTRIBUTION STATEMENT:

Per the terms and conditions imposed by CIPO, the publication of this dataset is subject to the following disclosure:

**Contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office.**

As a condition of using this dataset, all users are required to include the above attribution statement in all reproductions of the dataset. They are further required to cease using any record within the datasets that has been modified by CIPO and for which CIPO has issued a notice on its website in accordance with its Terms and Conditions, and to use the datasets in compliance with applicable laws. These requirements are in addition to the terms of the CC-BY-4.0 license, which require attribution to the author (among other terms). For further information on CIPO’s terms and conditions, see https://www.ic.gc.ca/eic/site/cipointernet-internetopic.nsf/eng/wr01935.html. For further information on the CC-BY-4.0 license, see https://creativecommons.org/licenses/by/4.0/. 

The following attribution statement, if included by users of this dataset, is satisfactory to the author, but the author makes no representations as to whether it may be satisfactory to CIPO:

**The Canada Trademarks Dataset is (c) 2021 by Jeremy Sheff and licensed under a CC-BY-4.0 license, subject to additional terms imposed by the Canadian Intellectual Property Office. It contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office. For further information, see https://creativecommons.org/licenses/by/4.0/ and https://www.ic.gc.ca/eic/site/cipointernet-internetopic.nsf/eng/wr01935.html.**

In addition to the csv and dta folders containing the dataset files, this repository also includes python scripts that can be used to download the CIPO IP Horizons historical trademarks data via SFTP and construct the csv data files. These scripts are also licensed for reuse subject to the terms of the CC-BY-4.0 license, and users are invited to adapt the scripts to their needs. These scripts require the user to obtain SFTP credentials from CIPO using the registration link provided at https://ised-isde.survey-sondage.ca/f/s.aspx?s=59f3b3a4-2fb5-49a4-b064-645a5e3a752d&lang=EN&ds=SFTP. They also require storage media with at least 70GB of free space. The python scripts can be found in the "py" folder within this repository.

Finally, this repository also includes Stata do-files used to convert the csv data files to .dta format and conduct the analyses set forth in the paper describing the dataset (forthcoming). These do-files are also licensed for reuse subject to the terms of the CC-BY-4.0 license, and users are invited to adapt the scripts to their needs.  The do-files can be found in the "do" folder within this repository.

**The first script that users should run is sftp_secure.py**. This script will prompt the user to enter their IP Horizons SFTP credentials; as noted above these can be obtained by registering with CIPO at https://ised-isde.survey-sondage.ca/f/s.aspx?s=59f3b3a4-2fb5-49a4-b064-645a5e3a752d&lang=EN&ds=SFTP. The script will also prompt the user to identify a target directory for the data downloads. Because the data archives are quite large, users are advised to create a target directory in advance and ensure they have at least 70GB of available storage on the media in which the directory is located.

The sftp_secure.py script will generate a new subfolder in the user’s target directory called **/XML_raw**. Users should note the full path of this directory, which they will be prompted to provide when running the remaining python scripts. Each of the remaining scripts, the filenames of which begin with **“iterparse”**, corresponds to one of the data files in the dataset, as indicated in the script’s filename. After running one of these scripts, the user’s target directory should include a /csv subdirectory containing the data file corresponding to the script; after running all the iterparse scripts the user’s /csv directory should be identical to the /csv directory in the public repository. Users are invited to modify these scripts as they see fit, subject to the terms of the licenses set forth above.

With respect to the Stata do-files, only one of them is relevant to construction of the dataset itself. This is **CA_TM_csv_cleanup.do**, which converts the .csv versions of the data files to .dta format, and uses Stata’s labeling functionality to reduce the size of the resulting files while preserving information. The other do-files generate the analyses and graphics presented in Parts II and III of the paper describing the dataset (forthcoming).
