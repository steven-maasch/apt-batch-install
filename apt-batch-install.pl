#!/usr/bin/perl -w

use strict;
use warnings;
use feature 'say';
use Getopt::Long;
use File::Basename;
use Text::CSV;

my $script = basename $0;
my $script_version = "0.0.1";

my $usage = "usage: $script --file file [--exclude] [package ...]
required arguments:
	--file		path to csv file
optional arguments:
	--exclude	seperated package names to exclude
";

&main();

my $csv_file = "";
my @exclude = "";

sub get_num_lines() {
	my %args = @_;
	my $file = $args{file} || die 'file=> parameter requierd';
	my $wc_out = qx(wc -l < $file); # line number without filename
	$wc_out =~ /(^\d{1,})/; 
	return $1;
}

sub install_package() {
	my %args = @_;
	my $package= $args{package} || die 'package=> parameter requierd';
	my $cmd_install = qx(apt-get install -y $package);
}
	
	
sub main {

	GetOptions("file=s" => \$csv_file, "exclude=s{1,}" => \@exclude);

	say "Start installing packages from $csv_file";
	
	my $num_lines = &get_num_lines(file=>$csv_file);
	say "Found $num_lines package(s) in file";
	my $num_excludes = @exclude;
	say "Exclude $num_excludes package(s): " . join(", ", @exclude);

	my @packages;
	my $csv = Text::CSV->new({ binary => 1 }) or 
		die "Can't use CSV: " . Text::CSV->error_diag();

	open my $fh, "<:encoding(utf8)", "test.csv" or die "test.csv: $!";
	while (my $row = $csv->getline($fh)) {
		my $package_name = $row->[0];
		my $package_repo = $row->[1];
		if (!($package_name ~~ @exclude)) {
			my $package = { "name" => $package_name };
			if ($package_repo) {
				$package->{"repo"} = $package_repo;
			}
			push (@packages, $package);
		}
	}

	$csv->eof or $csv->error_dialog();
	close $fh;
	
	
	for (@packages) {
		my $p_name = $_->{name};
		say "Processing package: $p_name";
		&install_package(package=>$p_name);
	}

	if ($? == -1) {
		print "command failed: $!\n";
	} else {
		print "Successfuly installed package ..";
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