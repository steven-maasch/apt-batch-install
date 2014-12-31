auto-install
============

Python script that batch installs apt-packages based on csv file(s).

##### Usage

```bash
$ sudo ./auto-install.py packages.csv
```
The CSV-File contains the following package information:
+ Column 1 : Package Name
+ Column 2 : Repository-URL (PPA)

The Repository-URL may be omitted.

##### Requirements

+ Python 3
