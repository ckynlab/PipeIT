#!/usr/bin/perl

use strict;

if (@ARGV!=3) {
	print "Usage: extract_pass_vcf.pl [input.vcf] [filtered.vcf] [filtered_out.vcf]"
}

open IN, "$ARGV[0]";
open OUT, ">$ARGV[1]";
open EXCLUDE, ">$ARGV[2]";

while (my $line = <IN>) {
	chomp $line;
	if ($line =~ /^\#/) { 
		print OUT $line."\n"; print EXCLUDE $line."\n";
	} else {
		my @line = split /\t/, $line;
		if ($line[6] eq "." || $line[6] eq "PASS" || $line[6] eq "HOTSPOT") {
			print OUT $line."\n";
		} elsif ($line[6] =~ /targetInterval/) { 
			print EXCLUDE $line."\n"; 
		} else {
			my @filters = split /;/, $line[6];
			my %filters = ();
			foreach my $filter (@filters) {
				$filters{$filter} = 1;
			}
	
			if (defined $filters{"HOTSPOT"}) {
			#	if (scalar keys %filters <=3 ) { 
					print OUT $line."\n";
			#	} else { print EXCLUDE $line."\n"; }
			} else { }
		}
	}
}
close IN;
close OUT;
close EXCLUDE;
