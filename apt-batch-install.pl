#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Text::CSV;
use Data::Dumper;

my $script = basename $0;
my $script_version = "0.0.1";

my $usage = "usage";

&main();

sub main {
	my @packages;
	my $csv = Text::CSV->new({ binary => 1 }) or die "Can't use CSV: " . Text::CSV->error_diag();

	open my $fh, "<:encoding(utf8)", "packages.csv" or die "packages.csv: $!";
	while (my $row = $csv->getline($fh)) {
		my $package_name = $row->[0];
		my $package_repo = $row->[1];
		my $package = { "name" => $package_name };
		if ($package_repo) {
			$package->{"repo"} = $package_repo;
		}
		push (@packages, $package);
	}
	print Dumper(\@packages);
	$csv->eof or $csv->error_dialog();
	close $fh;
	my $cmd_install = qx(apt-get install -y arj > /dev/null 2> /dev/null);
	system($cmd_install);
	if ($? == -1) {
		print "command failed: $!\n";
	} else {
		printf "command exited with value %d\n", $? >> 8;
	}
}

sub usage {
	print $usage;
	exit;
}

sub version {
	print "$script version $script_version\n";
	exit;
}

