#!/usr/bin/perl

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation;
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Following code validates matches in Brazilian Football A-Series (BCAS)
# Input uses two files (one for the matches and another for the official rankings) between 2003 and 2019
# Output is a report on matches that are not equal to the official version
# Author: Ricardo M. Czekster (rczekster@gmail.com)
# Date: 14/01/2020

use strict;
use warnings;

my $file = "../matches-2003-2019.txt";
my $class_file = "../ranking-2003-2019.txt";

# file containing the matches
open(INFILE, "<$file") or die("cannot open file named $file\n");
my(@lines) = <INFILE>;
close(INFILE);

# file containing the rankings
open(INFILE, "<$class_file") or die("cannot open file named $class_file\n");
my(@classificacoes) = <INFILE>;
close(INFILE);

###################
#process RANKING
my %c_classif;
foreach my $line (@classificacoes) {
   next if ($line =~ /^\s*#/);
   $line =~ s/\n//g;
   #print $line."\n";
   my($c_year,$c_rank,$c_team,$c_points,$c_win,$c_draw,$c_lost,$c_balance,$c_goals_pro,$c_goals_aga,$c_matches,$c_delta,$c_odds) = split(";", $line);
   $c_team = strip_accents($c_team);
   $c_classif{$c_year."-".$c_team."-points"} = $c_points;
   $c_classif{$c_year."-".$c_team."-goals-bal"} = $c_balance;
   $c_classif{$c_year."-".$c_team."-goals-pro"} = $c_goals_pro;
   $c_classif{$c_year."-".$c_team."-goals-aga"} = $c_goals_aga;
   $c_classif{$c_year."-".$c_team."-win"} = $c_win;
   $c_classif{$c_year."-".$c_team."-draw"} = $c_draw;
   $c_classif{$c_year."-".$c_team."-lost"} = $c_lost;
}


###################
#process MATCHES
my %teams;
my %stats;
my %partial_stats;
my $m;
$m = 0;
my $oldyear = 2003;

foreach my $line (@lines) {
   next if ($line =~ /^\s*#/);
   $line =~ s/\n//g;
   #print $line."\n";
   my($turn,$date,$time,$team1,$score,$team2) = split(";", $line);
   $team1 = strip_accents($team1);
   $team2 = strip_accents($team2);
   my($dd,$mm,$yy) = split("/", $date);
   my($score1,$score2) = split("x", $score);
   my $outcome1; my $outcome2;
   if ($score1 == $score2) { $outcome1 = $outcome2 = "D"; } #draw
   elsif ($score1 > $score2) { $outcome1 = "W"; $outcome2 = "L"; } #win
   else { $outcome1 = "L"; $outcome2 = "W"; } #lose
   $teams{$team1} .= $outcome1.";";
   $teams{$team2} .= $outcome2.";";
   # summing points
   if ($outcome1 eq "L") {
      $stats{$yy."-".$team1."-lost"}++;
   } elsif ($outcome2 eq "L") {
      $stats{$yy."-".$team2."-lost"}++;
   } 

   if ($outcome1 eq "W") {
      $stats{$yy."-".$team1."-points"} += 3;
      $stats{$yy."-".$team1."-win"}++;
   } elsif ($outcome2 eq "W") {
      $stats{$yy."-".$team2."-points"} += 3;
      $stats{$yy."-".$team2."-win"}++;
   } elsif ($outcome1 eq "D") {
      $stats{$yy."-".$team1."-points"} += 1;
      $stats{$yy."-".$team2."-points"} += 1;
      $stats{$yy."-".$team1."-draw"}++;
      $stats{$yy."-".$team2."-draw"}++;
   }

   # summing goals pro and goals against
   $stats{$yy."-".$team1."-goals-pro"} += $score1;
   $stats{$yy."-".$team1."-goals-aga"} += $score2;

   $stats{$yy."-".$team2."-goals-pro"} += $score2;
   $stats{$yy."-".$team2."-goals-aga"} += $score1;
   
   $stats{$yy."-".$team1."-goals-bal"} += ($score1 - $score2);
   $stats{$yy."-".$team2."-goals-bal"} += ($score2 - $score1);
}

# validation - show every inconsistency between the MATCHES file (FILE) and the RANKINGS file (OFFICIAL)
foreach my $key (sort keys %stats) {
   #print "key=$key\n";
   if ($key =~ /-points/) {
      my ($year,$team_name,$team_hash) = split("-", $key);
      my ($pts1,$bal1,$pro1,$aga1,$win1,$draw1,$lost1);
      $pts1 = $stats{$key};
      $bal1 = $stats{$year."-".$team_name."-goals-bal"};
      $pro1 = $stats{$year."-".$team_name."-goals-pro"};
      $aga1 = $stats{$year."-".$team_name."-goals-aga"};
      $win1 = $stats{$year."-".$team_name."-win"};
      $draw1 = $stats{$year."-".$team_name."-draw"};
      $lost1 = $stats{$year."-".$team_name."-lost"};

      my ($pts2,$bal2,$pro2,$aga2,$win2,$draw2,$lost2);
      $pts2 = $c_classif{$key};
      $bal2 = $c_classif{$year."-".$team_name."-goals-bal"};
      $pro2 = $c_classif{$year."-".$team_name."-goals-pro"};
      $aga2 = $c_classif{$year."-".$team_name."-goals-aga"};
      $win2 = $c_classif{$year."-".$team_name."-win"};
      $draw2 = $c_classif{$year."-".$team_name."-draw"};
      $lost2 = $c_classif{$year."-".$team_name."-lost"};
      
      if ($pts1 != $pts2) {
         print "[  FILE  ] $key => $pts1 - Balance: ".($bal1)." [$pro1,$aga1] WDL: [$win1,$draw1,$lost1]\n";
         print "[OFFICIAL] $key => $pts2 - Balance: ".($bal2)." [$pro2,$aga2] WDL: [$win2,$draw2,$lost2]\n\n";
      }
   }
}

sub strip_accents {
    my $str = shift;
    $str =~ s/á/a/g;
    $str =~ s/ã/a/g;
    $str =~ s/é/e/g;
    $str =~ s/ê/e/g;
    $str =~ s/í/i/g;
    $str =~ s/ó/o/g;
    $str =~ s/õ/o/g;
    $str =~ s/ú/u/g;
    $str =~ s/ç/c/g;
    $str
}
