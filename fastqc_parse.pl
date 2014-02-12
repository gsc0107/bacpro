#!/usr/bin/perl

# File:    fastqc_parse.pl
# Purpose: Parse FASTQC data file
# Author:  Richard Leggett, based on fastqc_parser_non_multi.pl

use Getopt::Long;

my $fastq_filename = "Undefined";
my $total_sequence = "Undefined";
my $read_length = "Undefined";
my $read_length_cutoff = 0;
my $q_target = 30;
my $q_reaches = 0;
my $n_overrepresented = 0;
my $overrep_status;
my $overrep_pc;
my $overrep_hit;
my $min_reads = 20000000;
my $html_format;

&GetOptions(
'fastqc:s'   => \$report_filename,
'minreads:i' => \$min_reads,
'q:i'        => \$q_target,
'html'       => \$html_format
);

die "Error: You must specify a FASTQC report filename\n" if not defined $report_filename;

open(FASTQCFILE, $report_filename) or die "Error: Can't open $report_filename\n";

while (<FASTQCFILE>) {
    chomp(my $line=$_);

    if ($line =~ /^Filename\t(\S+)/) {
        $fastq_filename = $1;
    } elsif ($line =~ /Total Sequences\t(\d+)/) {
        $total_sequence = $1;
    } elsif ($line =~ /Sequence length\t(\d+)/) {
        $read_length = $1;
        my $cutoff = 0.8*$read_length;
        $read_length_cutoff = sprintf("%.f", $cutoff);
    } elsif ($line =~ /Per base sequence quality/) {
        parse_per_base_sequence_quality();
    } elsif ($line =~ /Overrepresented sequences\t(\S+)/) {
        $overrep_status=$1;
        parse_overrepresented_sequences();
    }
}

close(FASTQCFILE);

while ($total_sequence =~ s/^(\d+)(\d\d\d)/$1,$2/) { 1 };

if (defined $html_format) {
    output_html();
} else {
    output_standard();
}


sub output_standard
{
    print "|", $fastq_filename;
    print "|", $total_sequence;
        
    if ($q_reaches >= $read_length_cutoff) {
        print "|", $q_reaches;
    } else {
        print "|{color:red}",$q_reaches, "{color}";    
    }
    if ($overrep_status eq "fail") {
        printf "|{color:red}%d hits, top (%.2f%%) is %s{color}|\\n\n", $n_overrepresented, $overrep_pc, $overrep_hit;
    } else {
        print "| |\\n\n";
    }
}

sub output_html
{
    print "<tr>";
    print "<td align=center>", $fastq_filename, "</td>";
    print "<td align=center>", $total_sequence, "</td>";
    
    if ($q_reaches >= $read_length_cutoff) {
        print "<td align=center>", $q_reaches, "</td>";
    } else {
        print "<td align=center><font color=red>",$q_reaches, "</font></td>";    
    }
    if ($overrep_status eq "fail") {
        printf "<td align=center><font color=red>%d hits, top (%.2f%%) is %s</font></td>", $n_overrepresented, $overrep_pc, $overrep_hit;
    } else {
        print "<td align=center>&nbsp</td>";
    }    
    print "</tr>\n";
}

sub parse_per_base_sequence_quality
{
    my @q_limits;
    my @q_values;
    my $n_values = 0;
    <FASTQCFILE>;
    
    while (<FASTQCFILE>) {
        chomp (my $line = $_);

        if ($line =~ /END_MODULE/) {
            last;
        } elsif ($line =~ /^(\S+)\t(\S+)\t(\S+)/) {
            my $base = $1;
            my $mean = $2;
            
            if ($base =~ /(\d+)\-(\d+)/) {
                $base = $2;
            }
            
            @q_limits[$n_values] = $base;
            @q_values[$n_values] = $mean;
            $n_values++;
        }
    }

    # Start at the end of the read and look for the last Q30 value
    for (my $i=$n_values-1; $i>=0; $i--) {
        if ($q_values[$i] >= $q_target) {
            $q_reaches = $q_limits[$i];
            last;
        }
    }
}

sub parse_overrepresented_sequences
{
    <FASTQCFILE>;    
    while (<FASTQCFILE>) {
        chomp (my $line = $_);
        
        if ($line =~ /END_MODULE/) {
            last;
        } elsif ($line =~ /^(\S+)\t(\d+)\t(\S+)\t(\S+)/) {
            my @arr = split(/\t/, $line);
            my $seq = $arr[0];
            my $count = $arr[1];
            my $pc = $arr[2];
            my $hit = $arr[3];
            
            $n_overrepresented++;
            
            if ($n_overrepresented == 1) {
                $overrep_pc = $pc;
                $overrep_hit = $hit;
            }
        }
    }
}
