#!/usr/bin/perl -w

use utf8;
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Text::CSV;
use 5.18.0;

my $script = basename $0;
my $script_version = "1.1";
my $sep = "-" x 80;

my $usage = <<EOQ;
Usage: $script [--help] --file FILE [--exclude] [PACKAGE ...]
	
Required arguments:
		--file		path to csv file
Optional arguments:
		--help		show this help message and exit
		--exclude	seperated package names to exclude
EOQ

my $help = "";
my $csv_file = "";
my @exclude = "";

&main();

sub main {
	my $ok = GetOptions(
		"file=s" => \$csv_file,
		"exclude=s{1,}" => \@exclude,
		"help" => \$help);
	
	if ($help || !$ok) {
		print $usage;
		exit;
	}

	say "Package file => $csv_file";
	say "Found " . &count_lines(file=>$csv_file) . " package(s) in file";
	say "Exclude " . scalar @exclude . " package(s) => @exclude" if @exclude;
	say "Start installing packages";
	say $sep;
	
	my @packages;
	my $csv = Text::CSV->new({ binary => 1 }) or 
		die "Can't use Text::CSV: " . Text::CSV->error_diag();

	open my $fh, "<:encoding(utf8)", $csv_file or die "$csv_file: $!";
	while (my $row = $csv->getline($fh)) {
		my $package_name = $row->[0];
		my $package_repo = $row->[1];
		if (!(grep(/^$package_name$/, @exclude))) {
			my $package = { "name" => $package_name };
			if ($package_repo) {
				$package->{"repo"} = $package_repo;
			}
			push (@packages, $package);
		}
	}

	$csv->eof or $csv->error_dialog();
	close $fh;

	&install_packages(packages=>\@packages);

}

sub count_lines() {
	my %args = @_;
	my $file = $args{file} || die 'file=> parameter requiered';
	my $wc_out = qx(wc -l < $file);
	$wc_out =~ /(^\d{1,})/;
	return $1;
}

sub install_packages() {
	my %args = @_;
	my $packages = $args{packages} || die 'packages=> paramter required';
	my @err_installed;

	for (@$packages) {
		my $p_name = $_->{name};
		my $p_repo = $_->{repo};

		say "Processing package: $p_name";
		say $sep;

		my $err = 0;
		
		if ($p_repo) {
			# Add repo
			system("add-apt-repository", "-y", $p_repo) == 0 or $err = 1;
			if (!$err) {
				# Update package index
				system("apt-get", "update") == 0 or $err = 1;	
			}
		}

		if (!$err) {
			# Install package
			system("apt-get", "install", "-y", $p_name) == 0 or $err = 1;
		}

		if ($err) {
			push(@err_installed, $p_name);
		}
		say $sep;
	}
	say "Complete!";

	my $num_total = @$packages;
	my $num_installed = $num_total - @err_installed;
	my $num_not_installed = @err_installed;
	say "Summery:";
	say "Total => $num_total package(s)";
	say "Installed => $num_installed package(s)";

	if (@err_installed) {
		say "Not installed  $num_not_installed packages(s) => @err_installed";
	}
}
