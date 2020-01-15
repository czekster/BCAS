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

# Following code performs a method to predict top and bottom four teams of Brazilian Football A-Series (BCAS)
# Input is a year (from 2003 to 2019).
# Output are several files (in folder ./output/) with the Markov Chains models and results for the parameters used.
# Author: Ricardo M. Czekster (rczekster@gmail.com)
# Date: 14/01/2020

use strict;
use warnings;

use File::Copy;

if (@ARGV != 1) { 
   print "missing YEAR parameter. \nusage: perl do-mc.pl YEAR\n";
   exit;
}

my $file = "../matches-2003-2019.txt";
# GLOBAL PARAMETERS
my $DEBUG_MC = 1;        # creates a file 'mc.txt' with all Markov Chains
my $METHOD   = 2;        # method=1 --> standard DTMC conversion from CTMC
                         # method=2 --> new method
my $DEC_SEPARATOR = ","; #it could be "." here (this is the Brazilian decimal separator)

open(INFILE, "<$file") or die("cannot open hash file named $file\n");
my(@lines) = <INFILE>;
close(INFILE);

# parameters
my %teams;
my $target_year = $ARGV[0];

######## exectute 'main' code
open(ALLFILE, ">>all-$target_year.txt") or die ("Could not open file 'all-$target_year.txt'\n");
print ALLFILE "target_year;helper;ssprob;state-sum\n"; #ssprob = steady state probability

# all possibilities in terms of year, matches, window size and overlap size

#match counter (usually from 1 to 38)
for (my $target_match = 19; $target_match <= 34; $target_match+=5) {
   #'good' sizes are 2, 3 and 4 (more, the number of windows is very reduced, may cause inconsistencies to the method)
   for (my $size = 2; $size <= 3; $size++) {
      # size of the window overlap
      for (my $overlap = 0; $overlap <= $size-1; $overlap++) { # orig: 0 to $size-1
         compute_all($target_year, $target_match, $size, $overlap);
      }
   }
}
close(ALLFILE);

#remove auxiliary files (a-year.txt and res-year.txt) and move results file and MC to output folder (output/)
move("dtmc-$target_year.txt", "output/dtmc-$target_year.txt") or die "Move dtmc-$target_year.txt -> output/dtmc-$target_year.txt failed: $!";
move("ctmc-$target_year.txt", "output/ctmc-$target_year.txt") or die "Move ctmc-$target_year.txt -> output/ctmc-$target_year.txt failed: $!";
move("mc-only-states-$target_year.txt", "output/mc-only-states-$target_year.txt") or die "Move mc-only-states-$target_year.txt -> output/mc-only-states-$target_year.txt failed: $!";
move("all-$target_year.txt", "output/all-$target_year.txt") or die "Move all-$target_year.txt -> output/all-$target_year.txt failed: $!";
system("del a-$target_year.txt res-$target_year.txt");

####### finish 'main'


sub compute_all {
   my $target_year = shift;
   my $target_match = shift;
   my $size = shift;
   my $overlap = shift;
   %teams = (); #re-initialize teams hash

   ##ROUND;DATE;HOUR;HOME-TEAM;SCORE;AWAY-TEAM
   my $match_num = 0;
   foreach my $line (@lines) {
      next if ($line =~ /^\s*#/);
      $line =~ s/\n//g;
      my($f_round,$f_date,$f_hour,$f_home,$f_score,$f_away) = split(";", $line);
      $f_home = strip_accents($f_home);
      $f_away = strip_accents($f_away);
      my($day,$month,$year) = split("/", $f_date);
      my($score_home,$score_away) = split("x", $f_score);
      next if ($target_year != $year);
      
      #process file after this
      #print "$match_num year=$year - home=$f_home - away=$f_away - score_home=$score_home - score_away=$score_away\n" if ($f_home eq "Cruzeiro/MG" || $f_away eq "Cruzeiro/MG");
      $teams{$f_home} .= ($score_home > $score_away ? "W" : $score_home == $score_away ? "D" : "L");
      $teams{$f_away} .= ($score_away < $score_home ? "L" : $score_home == $score_away ? "D" : "W");
      last if (length($teams{$f_home})-1 == $target_match+1);
   }
   prepare($target_year, $target_match, $size, $overlap);
}

sub prepare {
   my $target_year = shift;
   my $target_match = shift;
   my $size = shift;
   my $overlap = shift;

   #process 'window'
   foreach my $key (sort keys %teams) {
      my $path;
      my %mc; # markov chain
      my $from;
      my %statespace;
      my $nextstate = 0;
      $path = $teams{$key};
      my $windows = int(length($path)/$size);
      #print "len=$windows length(path)=".(length($path))." path=$path\n" if ($key eq "Internacional/RS");
      for (my $i = 0; $i < $windows; $i++) {
         my $idx;
         if ($i > 0) { $idx = $i * $size - $overlap; }
         else { $idx = $i * $size; }
         my $win_str = substr($path, $idx, $size);
         my $state = wdl($win_str); # discovers the state in terms of number of W, D, L
         #print "copying from ".($idx)." to ".($idx + $size)." state: ".($state)."\n" if ($key eq "Internacional/RS");
         #print "path=$path state=$win_str\n";
         if ($i != $windows - 1 && not exists($statespace{$state})) { # if last state, and the next ($state) does not exist, then dont put in the statespace and in MC
            $statespace{$state} = $nextstate++;
         }
         if ($i == 0) {
            $from = $state;
         } else {
            if ($i == $windows - 1 && not exists($statespace{$state})) { #if last state, if it doesn't exist, it should be to itself
               delete $statespace{$state};
            } else {
               $mc{$from."-".$state}++;
            }
            $from = $state; #updates 'old' state
         }
      }
      my $result = compute(\%statespace, \%mc, $key, $target_year, $target_match, $size, $overlap);
      my $helper = $key."-".$target_match."-".$size."-".$overlap; # the helper var contains the teams name ($key)
      print "$target_year;$helper;$result\n";
      print ALLFILE "$target_year;$helper;$result\n"; # $result has two values: prob and state-sum
      #last;
   }
}

sub compute {
   my %statespace = %{ $_[0] };
   my %mc = %{ $_[1] };
   my $teamname = $_[2];
   my $target_year = $_[3];
   my $target_match = $_[4];
   my $size = $_[5];
   my $overlap = $_[6];

   #state space
   my @state_names = ();  # saves the state name
   my @state_values = (); # computes the values for each WDL present in the state
   my $order = 0;
   foreach my $key (sort {$statespace{$a} <=> $statespace{$b}} keys %statespace) { # this will sort a hash by the values
      #print "$key => $statespace{$key}\n";
      push @state_names, $key;
      push @state_values, compute_values($key);
      $order++;
   }

   my @mc_arr_dtmc;
   my @mc_arr_ctmc;

   #initializes matrix
   for (my $i = 0; $i < $order; $i++) {
      for (my $j = 0; $j < $order; $j++) {
         $mc_arr_dtmc[$i][$j] = 0;
      }
   }

   #creates the CTMC matrix
   foreach my $key (sort keys %mc) {
      #print "$key => $mc{$key}\n";
      my ($state_from,$state_to) = split("-",$key);
      $mc_arr_dtmc[$statespace{$state_from}][$statespace{$state_to}] = $mc{$key};
   }

   if ($METHOD == 1) {
      for (my $i = 0; $i < $order; $i++) {
         my $line_sum = 0;
         for (my $j = 0; $j < $order; $j++) {
            if ($i != $j) {
               $line_sum += $mc_arr_dtmc[$i][$j]
            }
            $mc_arr_ctmc[$i][$j] = $mc_arr_dtmc[$i][$j]; # saves the CTMC (for debugging)
         }
         $mc_arr_dtmc[$i][$i] = $line_sum * (-1); 
      }
      #find max_value (it will be at the diagonal, certainly (in module)
      my $max_value = -1;
      for (my $i = 0; $i < $order; $i++) {
         if ($mc_arr_dtmc[$i][$i] < $max_value) {
            $max_value = $mc_arr_dtmc[$i][$i];
         }
      }
      #print "max_value=$max_value\n";
      #transforms the CTMC to a DTMC
      for (my $i = 0; $i < $order; $i++) {
         for (my $j = 0; $j < $order; $j++) {
            $mc_arr_dtmc[$i][$j] = ($i == $j ? 1 - $mc_arr_dtmc[$i][$j] / $max_value : (-1) * $mc_arr_dtmc[$i][$j] / $max_value);
         }
      }
      
   } elsif ($METHOD == 2) {
      my $sum = 0; # sum of all elements - method2
      for (my $i = 0; $i < $order; $i++) {
         for (my $j = 0; $j < $order; $j++) {
            $sum += $mc_arr_dtmc[$i][$j];
         }
      }
      for (my $i = 0; $i < $order; $i++) {
         my $line_sum = 0;
         for (my $j = 0; $j < $order; $j++) {
            $line_sum += $mc_arr_dtmc[$i][$j];
            $mc_arr_ctmc[$i][$j] = $mc_arr_dtmc[$i][$j]; # saves the CTMC (for debugging)
         }
         for (my $j = 0; $j < $order; $j++) {
            $mc_arr_dtmc[$i][$j] = $mc_arr_dtmc[$i][$j] / ($line_sum == 0 ? 1 : $line_sum);
         }
      }      
   }

   if ($DEBUG_MC) {
      #prints the DTMC
      open(MCFILE, ">>dtmc-$target_year.txt") or die ("Could not open file 'dtmc-$target_year.txt'\n");
      print MCFILE "$teamname;$target_match;$size;$overlap\n";
      for (my $i = 0; $i < $order; $i++) {
         print MCFILE ";$state_names[$i]";
      }
      print MCFILE "\n";
      
      for (my $i = 0; $i < $order; $i++) {
         print MCFILE "$state_names[$i]";
         for (my $j = 0; $j < $order; $j++) {
            print MCFILE ";$mc_arr_dtmc[$i][$j]";
         }
         print MCFILE "\n";
      }
      #print MCFILE "\n";
      close(MCFILE);

      #prints the CTMC
      open(MCFILE, ">>ctmc-$target_year.txt") or die ("Could not open file 'ctmc-$target_year.txt'\n");
      print MCFILE "$teamname;$target_match;$size;$overlap\n";
      for (my $i = 0; $i < $order; $i++) {
         print MCFILE ";$state_names[$i]";
      }
      print MCFILE "\n";
      
      for (my $i = 0; $i < $order; $i++) {
         print MCFILE "$state_names[$i]";
         for (my $j = 0; $j < $order; $j++) {
            print MCFILE ";$mc_arr_ctmc[$i][$j]";
         }
         print MCFILE "\n";
      }
      print MCFILE "\n";
      close(MCFILE);

      #creates another file with only the states 
      open(MCFILE2, ">>mc-only-states-$target_year.txt") or die ("Could not open file 'mc-only-states-$target_year.txt'\n");
      print MCFILE2 "$teamname;$target_match;$size;$overlap;";
      for (my $i = 0; $i < $order; $i++) {
         print MCFILE2 "$state_names[$i];";
      }
      print MCFILE2 "\n";
      close(MCFILE2);
   }
   
   #create a file for the aux matrix
   open(OUTFILE, ">a-$target_year.txt") or die ("Could not open file 'a-$target_year.txt'\n");
   for (my $i = 0; $i < $order; $i++) {
      for (my $j = 0; $j < $order; $j++) {
         print OUTFILE "$mc_arr_dtmc[$i][$j] ";
      }
      print OUTFILE "\n";
   }
   close(OUTFILE);
   # system call for the vector matrix product (external executable written in C) -- it uses two temporary auxiliary files (a-YYYY.txt and res-YYYY.txt)
   system("vector-matrix-product-file.exe a-$target_year.txt > res-$target_year.txt");

   #open results file
   open(RESFILE, "<res-$target_year.txt") or die ("Could not open file 'res-$target_year.txt'\n");
   my($res) = <RESFILE>;
   close(RESFILE);
   
   my @results = split(";", $res);

   if ($DEBUG_MC) {
      open(MCFILE, ">>dtmc-$target_year.txt") or die ("Could not open file 'dtmc-$target_year.txt'\n");
      for (my $k = 0; $k < @results; $k++) {
         print MCFILE ($k == 0 ? "[" : "")."".$results[$k].($k == @results-1 || $k == 0 ? "" : ";").($k == 0 ? "];" : "");
      }
      print MCFILE "\n";
      close(MCFILE);
   }
   
   my $result_final = 0;
   my $state_sums = 0;
   for (my $i = 0; $i < @state_values; $i++) {
      $result_final += $results[$i+1] * $state_values[$i]; # + 1 because the first element indicates whether the method has converged or not (look at the executable)
      $state_sums += $state_values[$i];
   }
   my $ret_val = $result_final.";".$state_sums;
   $ret_val =~ s/\./$DEC_SEPARATOR/g;
   $ret_val
}

# this is the worst sub I've ever coded - and I will not change it (pure lazyness).............
sub compute_values {
   my $statename = shift;
   my $len = length($statename);
   my $res = 0;
   if ($len == 2) {
      my $ch = substr($statename, 0, 1);
      my $val = substr($statename, 1, 1);

      if ($ch eq "W") { $res += 3*$val; }
      elsif ($ch eq "D") { $res += 1*$val; }
   } elsif ($len == 4) {
      my $ch1 = substr($statename, 0, 1);
      my $val1 = substr($statename, 1, 1);
      if ($ch1 eq "W") { $res += 3*$val1; }
      elsif ($ch1 eq "D") { $res += 1*$val1; }

      my $ch2 = substr($statename, 2, 1);
      my $val2 = substr($statename, 3, 1);
      if ($ch2 eq "W") { $res += 3*$val2; }
      elsif ($ch2 eq "D") { $res += 1*$val2; }
   } elsif ($len == 6) {
      my $ch1 = substr($statename, 0, 1);
      my $val1 = substr($statename, 1, 1);
      if ($ch1 eq "W") { $res += 3*$val1; }
      elsif ($ch1 eq "D") { $res += 1*$val1; }

      my $ch2 = substr($statename, 2, 1);
      my $val2 = substr($statename, 3, 1);
      if ($ch2 eq "W") { $res += 3*$val2; }
      elsif ($ch2 eq "D") { $res += 1*$val2; }

      my $ch3 = substr($statename, 4, 1);
      my $val3 = substr($statename, 5, 1);
      if ($ch3 eq "W") { $res += 3*$val3; }
      elsif ($ch3 eq "D") { $res += 1*$val3; }
   }
   return $res;
}

sub wdl {
   my $str = shift;
   my ($c_W,$c_D,$c_L) = (0,0,0); #counters
   for (my $i = 0; $i < length($str); $i++) {
      if (substr($str,$i,1) eq "W") {
         $c_W++;
      } elsif (substr($str,$i,1) eq "D") {
         $c_D++;
      } else {
         $c_L++;
      }
   }
   my $ss = "";
   if ($c_W > 0) {
      $ss .= "W".$c_W;
   }
   if ($c_D > 0) {
      $ss .= "D".$c_D;
   }
   if ($c_L > 0) {
      $ss .= "L".$c_L;
   }
   $ss
}

sub strip_accents {
    my $str = shift;
    $str =~ s/á/a/g;
    $str =~ s/ã/a/g;
    $str =~ s/é/e/g;
    $str =~ s/ê/e/g;
    $str =~ s/í/i/g;
    $str =~ s/ó/o/g;
    $str =~ s/ô/o/g;
    $str =~ s/ú/u/g;
    $str =~ s/ç/c/g;
    $str
}
