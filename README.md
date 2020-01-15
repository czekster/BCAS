# BCAS - Brazilian Championship A-Series
This is the repository for the BCAS (Brazilian Championship A-Series).
It contains the matches with date/hour, host team, score, visiting team.
More details on ResearchGate.

Files:
- /
  - ranking-2003-2019.txt -- official rankings for BCAS
  - matches-2003-2019.txt -- all matches played from 2003 to 2019 in BCAS
  - average-attendance-2003-2019.txt -- average attendance (average number of supporters in stadia) for all teams in BCAS
  - process/ -- contains the Perl files
    - do-all.bat
    - do-mc.pl
    - do-validation.pl
    - vector-matrix-product-file.c
    - spreadsheets/ -- analysis files
      - Analysis.xlsx
      - Results-All.xlsx
      - Simple-MC.xlsx
      - Simple-MC-new-method.xlsx
    - process/output/ -- analysis files

- [Download Perl (5.28)](https://www.activestate.com/products/perl/downloads/)
- Run:
  - PROMPT: perl do-mc.pl 2006
    - this will execute the process for year 2006 (Y=2006) generating several files in the output/ folder
 
# How to cite this work
Ricardo M. Czekster, *Predicting Brazilian Football Championship first and last four teams between 2006 to 2019 since mid-season*, Jan/2020 (non peer reviewed pre-print), DOI: 10.13140/RG.2.2.33748.96646

[Link to ResearchGate](https://www.researchgate.net/publication/338595720_Predicting_Brazilian_Football_Championship_first_and_last_four_teams_between_2006_to_2019_since_mid-season)
