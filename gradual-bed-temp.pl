#!/usr/bin/perl

# Post-processing script to adjust bed temperature gradually based
# on amount of material extruded. Works only with absolute E

use strict;
use warnings;

# change these to suit your needs
my $start_temp = 80; # it will heat bed to this temperature when print starts
my $end_temp = 65; # this will be temperature at the print finish


my $end_e = 0;
my $e = 0;
my @gcode;

# find end E value
open(my $fh, '<', $ARGV[0]);

while (<$fh>) {
	$end_e += ($e - $1) if /G92 E\s*(\d+(\.\d+)?)/ && !/^\s*;/;
	$e = $1 if /E\s*(\d+(\.\d+)?)/ && !/G92/ && !/^\s*;/;
	push(@gcode, $_);
}

close $fh;

$end_e += $e;

# write out processed output
open(my $fhout, '>', $ARGV[0]);

my $current_e = 0;
my $temp_diff = $start_temp - $end_temp;
$e = 0;

foreach (@gcode) {
	print $fhout $_;

	$current_e += ($e - $1) if /G92 E\s*(\d+(\.\d+)?)/ && !/^\s*;/;
	$e = $1 if /E\s*(\d+(\.\d+)?)/ && !/G92/ && !/^\s*;/;

	if ( /Z/ && !/^\s*;/ ) {
		my $current_temp = $end_temp + $temp_diff * (1 - ($current_e + $e) / $end_e);
		print $fhout sprintf("M140 S%d\n", $current_temp);
	}
}

close $fhout;
