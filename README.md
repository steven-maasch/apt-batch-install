apt-batch-install
============

My first Perl script that batch installs apt-packages based on a csv file.

#### Usage

```bash
apt-batch-install.pl --file FILE [--exclude] [PACKAGE ...]

required arguments:
	--file		path to csv file
optional arguments:
	--exclude	seperated package names to exclude (not installing)
```

The CSV-File contains the following information:
+ Column 1 : Package Name
+ Column 2 : Repository-URL (PPA)

The Repository-URL may be omitted.

#### Example usage
```bash
$ sudo ./apt-batch-install.pl --file packages.csv -- exclude hplip texlive-full
```

#### Requirements

+ Perl 5
+ Text::CSV (CPAN)
