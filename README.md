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
 
