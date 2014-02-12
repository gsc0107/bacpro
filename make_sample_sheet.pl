#!/usr/bin/perl -w

# Program: make_sample_sheet.pl
# Purpose: Convert instrument sample sheet into Casava friendly format,
#          creating multiple parts as necessary for BACs.
# Author:  Richard Leggett
#          richard.leggett@tgac.ac.uk

use warnings;
use strict;
use Getopt::Long;

my $input_filename;
my $line;
my @linearr;
my $flowcell;
my $control = "N";
my $recipe = "NA";
my $operator = "TGAC PAP";
my $project;
my $file_counter=1;
my $current_lane=0;
my $current_file;
my $line_count=0;
my $max_lines=768;
my $output_file_open = 0;
my $nolanecolumn;
my $mergedid;
my $lane = 1;
my $help;

&GetOptions(
'h'            => \$help,
'help'         => \$help,
'input:s'      => \$input_filename,
'operator:s'   => \$operator,
'flowcell:s'   => \$flowcell,
'project:s'    => \$project, 
'nolanecolumn' => \$nolanecolumn,
'mergedid'     => \$mergedid,
'lane:s'       => \$lane
);

if (defined $help) {
    print "\n",
          "make_sample_sheet.pl\n",
          "\n".
          "Convert instrument sample sheet into Casava friendly format.\n", 
          "Creates multiple parts as necessary for BACs.\n",
          "\n",
          "Options:\n",
          "\n",
          "-input <filename> specifies input .csv file\n",
          "-operator <name>  specifies the name of the operator\n",
          "-flowcell <id>    specifies the flowcell ID\n",
          "-project <name>   specifies the project name\n".
          "-lane <number>    specifies the lane number (default 1)\n",
          "-nolanecolumn     specifies the input file does not have a lane column\n".
          "-mergeid          specifies merged sample ID\n",
          "\n",
          "Example: make_sample_sheet.pl -input IPOi1230.csv -operator \"Richard Leggett\"\n",
          "                              -flowcell C3FYKACXX -lane 1 -nolanecolumn\n",
          "                              -project \"Theme1wholegenomesequencingforBBSRC_Wheat_LoLa\"\n",
          "\n";
    exit;
}

die "You must specify a -input parameter\n" if (not defined $input_filename);
die "You must specify a -operator parameter\n" if (not defined $operator);
die "You must specify a -flowcell parameter\n" if (not defined $flowcell);
die "You must specify a -project parameter\n" if (not defined $project);

open(INPUTFILE, $input_filename) or die "Can't open $input_filename\n";

chomp($line = <INPUTFILE>);
@linearr = split(/,/, $line);
die "Header not found" if ($linearr[0] ne "[Header]");

# Header section
while ($linearr[0] ne "[Reads]") {
    chomp($line = <INPUTFILE>);
    @linearr = split(/,/, $line);
    $linearr[0] = "" if not defined $linearr[0]; 
}

# Reads section
while ($linearr[0] ne "[Settings]") {
    chomp($line = <INPUTFILE>);
    @linearr = split(/,/, $line);
    $linearr[0] = "" if not defined $linearr[0];  
}

# Settings section
while ($linearr[0] ne "[Data]") {
    chomp($line = <INPUTFILE>);
    @linearr = split(/,/, $line);
    $linearr[0] = "" if not defined $linearr[0];
}

<INPUTFILE>;
# Data section
while(<INPUTFILE>) {
    chomp($line = $_);
    @linearr = split(/,/, $line);
    for (my $i=0; $i<@linearr; $i++) {
        chomp($linearr[$i]);
        $linearr[$i] =~ s/^ //;
        $linearr[$i] =~ s/ $//;
    }

    my $sample_id;
    my $sample_ref;
    my $index;
    my $description = "";

    if (defined $nolanecolumn) { 
        $linearr[5] =~ s/ //g;
        $linearr[7] =~ s/ //g;
        if (defined $mergedid) {
            $sample_id = $linearr[0]."_".$linearr[1];
        } else {
            $sample_id = $linearr[0];
        }
        $sample_ref = $linearr[1];
        $index = $linearr[5]."-".$linearr[7];
    } else {
        $linearr[6] =~ s/ //g;
        $linearr[8] =~ s/ //g;
        $lane = $linearr[0];
        if (defined $mergedid) {
            $sample_id = $linearr[1]."_".$linearr[2];
        } else {
            $sample_id = $linearr[1];
        }
        $sample_ref = $linearr[2];
        $index = $linearr[6]."-".$linearr[8];
    }

    #my $project = $linearr[9];
    
    if ($lane != $current_lane) {
        if ($output_file_open == 1) {
            close($current_file);
        }
        $file_counter = 1;   
        $line_count = 0;
        $current_lane = $lane;     
    }


    if ($line_count == $max_lines) {
        close($current_file);
        $file_counter++; 
        $line_count = 0;
    }

    if ($line_count == 0) {
        open($current_file, ">SampleSheet-lane".$lane."-".$file_counter.".csv") or die "Can't open output file\n";
        print $current_file "FCID,Lane,SampleID,SampleRef,Index,Description,Control,Recipe,Operator,Project\n";
        $output_file_open = 1;
    }

    print $current_file $flowcell,",",$lane,",",$sample_id,",",$sample_ref,",",$index,",",$description,",",$control,",",$recipe,",",$operator,",",$project,"\n";
    $line_count++;
}

close(INPUTFILE);

if ($output_file_open) {
    close($current_file);
}
