# CanadaTM
The Canada Trademarks Dataset

18 Journal of Empirical Legal Studies (forthcoming 2021), available at https://papers.ssrn.com/abstract=3782655

Dataset Selection and Arrangement (c) 2021 Jeremy Sheff

Python and Stata Scripts (c) 2021 Jeremy Sheff

Contains data licensed by Her Majesty the Queen in right of Canada, as represented by the Minister of Industry, the minister responsible for the administration of the Canadian Intellectual Property Office. 

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
