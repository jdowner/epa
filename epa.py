#!/usr/bin/env python

"""
Name:
    epa

Usage:
    epa list
    epa create
    epa enter <environment>

"""

from __future__ import print_function

import subprocess
import tempfile
import os
import sys

import yaml

import docopt


def command(cmd):
    return subprocess.check_output(cmd, shell=True, executable="/bin/bash")


def which(name):
    try:
        return command("which {}".format(name)).strip()
    except subprocess.CalledProcessError:
        return None


class RequirementsParser(object):
    def __init__(self):
        pass


def create_virtual_environment(env):
    binary_path = which(env)
    if binary_path is None:
        print("warning: {} unavailable".format(env), file=sys.stderr)
        return

    command("virtualenv -p {} .epa/{}".format(binary_path, env))


def main(argv=sys.argv[1:]):
    args = docopt.docopt(
            __doc__,
            argv=argv,
            )

    if args["create"]:
        with open("epa.yaml") as fp:
            config = yaml.load(fp)

        for env in config["environments"]:
            create_virtual_environment(env)

    if args["enter"]:

        with tempfile.NamedTemporaryFile() as fp:
            path = "/home/jdowner/repos/.epa/{}/bin/activate".format(args["<environment>"])

            fp.write(open(os.path.expanduser("~/.bashrc")).read())
            fp.write("source {}".format(path))

            print(fp.name)
            os.execv("/bin/bash", ["--rcfile {}".format(fp.name)])

    if args["list"]:
        print("list")


if __name__ == "__main__":
    main()
