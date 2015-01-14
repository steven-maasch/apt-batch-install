#!/usr/bin/perl -w

use utf8;
use strict;
use warnings;
use feature 'say';
use Getopt::Long;
use File::Basename;
use Text::CSV;

our $script = basename $0;
our $script_version = "1.0";

my $usage = "usage: $script [--help] --file FILE [--exclude] [PACKAGE ...]
required arguments:
	--file		path to csv file
optional arguments:
	--help		show this help message and exit
	--exclude	seperated package names to exclude
";

&main();

my $csv_file = "";
my @exclude = "";

sub main {
	GetOptions("file=s" => \$csv_file, "exclude=s{1,}" => \@exclude);

	say "Start installing packages from $csv_file";
	
	my $num_lines = &get_num_lines(file=>$csv_file);
	say "Found $num_lines package(s) in file";
	my $num_excludes = @exclude;
	say "Exclude $num_excludes package(s) => @exclude" if (@exclude);

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

	&install_packages(packages=>\@packages);

}

sub get_num_lines() {
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
		say "$_";
		my $p_name = $_->{name};
		my $p_repo = $_->{repo};
		
		say "Processing package: $p_name";
		
		my $err = 0;
		
		if ($p_repo) {
			system("add-apt-repository", "-y", $p_repo) == 0 or $err = 1;
			system("apt-get", "update") unless ($err);
			$err = 1 if ($?);
		}
		system("apt-get", "install", "-y", $p_name) unless $err;
		$err = 1 if ($?);
		
		if ($err) {
			push(@err_installed, $p_name);
		}
	}
	say "Complete!";
	
	my $num_total = @$packages;
	my $num_installed = @$packages - @err_installed;
	my $num_not_installed = @err_installed;
	say "Summery:";
	say "\tTotal: $num_total package(s)";
	say "\tInstalled: $num_installed package(s)";
	say "\tNot installed: $num_not_installed packages(s) => @err_installed" if (@err_installed);
}

sub usage {
	print $usage;
	exit;
}

sub version {
	print "$script version $script_version\n";
	exit;
}