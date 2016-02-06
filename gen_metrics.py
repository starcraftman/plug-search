#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module to re(generate) metrics.json database.
"""
from __future__ import absolute_import

import argparse
from argparse import RawDescriptionHelpFormatter as RawDescriptionHelp
import json
import os
import shlex
import shutil
import subprocess as sub
import tempfile

ROOT = os.path.abspath(os.path.dirname(__file__))
if os.path.dirname(__file__) == '':
    ROOT = os.getcwd()


def create_args_parser():
    """
    Create argument parser.
    """
    prog_name = os.path.basename(__file__)[0:-3]
    mesg = """
    Generate the metrics.json database that
    contains metrics scraped from plugins.

    Do NOT edit the generated file. Just regenerate it.
    """.format(prog_name.capitalize(), prog_name)
    mesg = mesg[0:-5]
    parser = argparse.ArgumentParser(prog=prog_name, description=mesg,
                                     formatter_class=RawDescriptionHelp)
    parser.add_argument('input', default=os.path.join(ROOT, 'db.json'),
                        help='input json file to transform')
    parser.add_argument('output', nargs='?',
                        help='output json, by default metrics.json')

    return parser


def github_uri(plug_name):
    """
    Just make the standard public https uri.
    """
    return 'https://github.com/' + plug_name


def run_cmd(cmd):
    """
    Just run commands and return output. It is 1 long string.
    """
    return sub.check_output(shlex.split(cmd))


def git_dates(plug_name):
    """
    Get first and last author commit dates.

    Returns:
        (first_commit_date, latest_commit_date)
    """
    try:
        orig_dir = os.getcwd()
        tempd = tempfile.mkdtemp()
        run_cmd('git clone {} {}'.format(github_uri(plug_name), tempd))
        os.chdir(tempd)

        first_rev = run_cmd('git rev-list --max-parents=0 HEAD')
        start = run_cmd('git log --pretty=format:"%ad" ' + first_rev)
        end = run_cmd('git log --pretty=format:"%ad" -n 1')
        return (start, end)
    finally:
        os.chdir(orig_dir)
        shutil.rmtree(tempd)


def add_metrics(metrics, plug_name):
    """
    Add useful metrics to the db.
    Includes:
    - # of stars/watches on github.
    - Last commit date.
    - First commit date.
    """
    start, end = git_dates(plug_name)
    # TODO: Fetch github stars.
    # TODO: Fetch github dotfiles inclusions.
    metrics[plug_name] = {
        'start_date': start,
        'end_date': end,
    }


def main():
    """
    Main entry point.
    """
    parser = create_args_parser()
    args = parser.parse_args()
    if args.output is None:
        args.output = os.path.join(os.path.dirname(args.input), 'metrics.json')

    with open(args.input, 'r') as fin:
        plugs = json.load(fin)

    metrics = {}
    for plug in plugs:
        add_metrics(metrics, plug)

    with open(args.output, 'w') as fout:
        json.dump(metrics, fout, sort_keys=True,
                  indent=2, separators=(',', ': '))


if __name__ == "__main__":
    main()
