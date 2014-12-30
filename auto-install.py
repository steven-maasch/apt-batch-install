#!/usr/bin/python3.4

import os
import sys
import argparse
import csv
import subprocess
from subprocess import CalledProcessError

FNULL = open(os.devnull, "w")
CMD_ADD_REPO = "add-apt-repository -y {url}"
CMD_INSTALL = "apt-get install -y {package}"
CMD_FETCH_PACKAGES = "apt-get update".split()

def is_root():
    return os.getuid() == 0

def add_options(parser):
    parser.add_argument("-f", "--file", dest="filename",
                        help="", metavar="FILE")

def add_repo(repo_url):
    cmd = CMD_ADD_REPO.format(url=repo_url).split(" ")
    subprocess.check_call(cmd, stdout=FNULL, stderr=FNULL)

def fetch_package_list():
    subprocess.check_call(CMD_FETCH_PACKAGES, stdout=FNULL, stderr=FNULL)

def install_package(package_name):
    cmd = CMD_INSTALL.format(package=package_name).split(" ")
    subprocess.check_call(cmd, stdout=FNULL, stderr=FNULL)

def file_to_seq(fp):
    out = []
    reader = csv.DictReader(fp,
            fieldnames=["package_name", "repo"])
    for row in reader:
        out.append(row)
    return out

def indent(num_spaces):
    sys.stdout.write(" " * num_spaces)

def main():
    arg_parser = argparse.ArgumentParser()
    add_options(arg_parser)
    args = arg_parser.parse_args()

    if not is_root():
        print("ERROR: Please run script with root privileges.")
        return 1

    with open(args.filename, "r") as fp:
        packages = file_to_seq(fp)

    num_packages = len(packages)
    num_success = 0

    print("{} -> {} Packages found.".format(args.filename, num_packages))
    print("Start installing Packages:")

    for i in range(num_packages):
        package = packages[i]
        err = False

        print("Processing Package: {:40s} {}/{}".format(
            package["package_name"],
            i + 1,
            num_packages))

        if package["repo"] != "":
            try:
                # Add new package repo
                indent(2)
                sys.stdout.write("Add Repo: {}".format(package["repo"]))
                add_repo(package["repo"])
                sys.stdout.write(" -> ")
                sys.stdout.write("OK")
                sys.stdout.write("\n")

                # Update package list
                indent(2)
                sys.stdout.write("Update Package List")
                fetch_package_list()
                sys.stdout.write(" -> ")
                sys.stdout.write("OK")
                sys.stdout.write("\n")
            except CalledProcessError:
                err = True
                sys.stdout.write(" -> ")
                sys.stdout.write("ERROR")
                sys.stdout.write("\n")
            sys.stdout.flush()

        # Install new package
        if not err:
            indent(2)
            sys.stdout.write("Installing")
            try:
                install_package(package["package_name"])
                sys.stdout.write(" -> ")
                sys.stdout.write("OK")
                num_success += 1
            except CalledProcessError:
                sys.stdout.write(" -> ")
                sys.stdout.write("ERROR")
            sys.stdout.write("\n")
            sys.stdout.flush()

    print("")
    print("Complete!")
    print("")
    print("Summary:")
    indent(2)
    print("Installed: {} Package(s)".format(num_success))
    indent(2)
    print("Not Installed: {} Package(s)".format(num_packages - num_success))

    return 0

if __name__ == "__main__":
    main()
