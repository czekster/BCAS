# BCAS - Brazilian Championship A-Series
This is the repository for the BCAS (Brazilian Championship A-Series).
It contains the matches with date/hour, host team, score, visiting team.
More details on ResearchGate.

Files:
- /
  - ranking-2003-2019.txt -- official rankings for BCAS
  - matches-2003-2019.txt -- all matches played from 2003 to 2019 in BCAS
  - average-attendance-2003-2019.txt -- average attendance (average number of supporters in stadia) for all teams in BCAS
  - process/ -- contains the Perl, C, batch, MS-Excel files
    - do-mc.pl -- **this is the *main* Perl script, the one that does all the process described in the paper**
    - do-all.bat -- runs *many* years in parallel (use with caution, your CPU may use all cores at once)
    - do-validation.pl -- this script runs the validation, i.e., it compares official ranking and statistics with my dataset (this is just an auxiliary process)
    - vector-matrix-product-file.c -- performs the Vector-Matrix Product (VMP) to compute the probability vector for each team
    - spreadsheets/ -- statistical analysis files (auxiliary file, for computing some of BCAS statistics described in the paper)
      - Analysis.xlsx
      - Results-All.xlsx
      - Simple-MC.xlsx
      - Simple-MC-new-method.xlsx
    - ./output/ -- generated script output and analysis files

- [Download Perl (5.28)](https://www.activestate.com/products/perl/downloads/)
- Run:
  - PROMPT: perl do-mc.pl 2006
    - this will execute the process for year 2006 (Y=2006) generating several files in the output/ folder

# How to create a new analysis session
The idea is to be able to change parameters and inspect generated output for insight.

*1. Change parameters in script _do-mc.pl YEAR_ (YEAR is the command line parameter):*
The following set of parameters may be changed:
- M: number of matches to analyse (as M is close to 1, less information will be used to count the frequencies between states)
- W: window size (from 2 to 19, however, if 19 is chosen, the frequency will be very low)
- O: overlap between windows (it is currently set to go from zero to (W-1)

There is one constant that you should consider: $METHOD = 2; (it is currently using the _modified_ DTMC instead of standard DTMC)

*2. Run the script for a year:*
PROMPT: perl do-mc.pl 2010

*3. Observe output in folder ./output/*
- the following files will be generated: 
  - ./output/all-2010.txt  --> **this is the place with all the results**
  - ./output/dtmc-2010.txt  --> file with all team's DTMC (Discrete Time Markov Chain)
  - ./output/ctmc-2010.txt  --> file with all team's CTMC (Continuous Time Markov Chain)
  - ./output/mc-only-states-2010.txt  --> shows only the observed states for each team for that year
  
*4. Use MS-Excel or similar software to analyse generated output*
- Look at folder ./spreadsheets/ for examples 

# How to cite this work
Ricardo M. Czekster, *Predicting Brazilian Football Championship first and last four teams between 2006 to 2019 since mid-season*, Jan/2020 (non peer reviewed pre-print), DOI: 10.13140/RG.2.2.33748.96646/2

[Link to ResearchGate](https://www.researchgate.net/publication/338595720_Predicting_Brazilian_Football_Championship_first_and_last_four_teams_between_2006_to_2019_since_mid-season)
