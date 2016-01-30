#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module to re(generate) tags.json database.
Do NOT edit the tags.json file.
"""
from __future__ import absolute_import

import argparse
from argparse import RawDescriptionHelpFormatter as RawDescriptionHelp
import json
import os

ROOT = os.path.abspath(os.path.dirname(__file__))
if os.path.dirname(__file__) == '':
    ROOT = os.getcwd()


def create_args_parser():
    """
    Create argument parser.
    """
    prog_name = os.path.basename(__file__)[0:-3]
    mesg = """
    Generate the tags.json database that maps
    tags onto plugin names.

    Do NOT edit the tags.json file.
    To update tags, edit db.json and regenerate.
    """.format(prog_name.capitalize(), prog_name)
    mesg = mesg[0:-5]
    parser = argparse.ArgumentParser(prog=prog_name, description=mesg,
                                     formatter_class=RawDescriptionHelp)
    parser.add_argument('-i', '--input',
                        default=os.path.join(ROOT, 'db.json'),
                        help='input json file to transform into tags')
    parser.add_argument('-o', '--output',
                        help='output json, by default tags.json in input dir')

    return parser


def add_tags(tags, plugin, plugin_tags):
    """
    Add plugin name to all relevant tags.
    """
    for tag in plugin_tags:
        if tag not in tags:
            tags[tag] = []
        tags[tag].append(plugin)


def main():
    """
    Main entry point.
    """
    parser = create_args_parser()
    args = parser.parse_args()
    if args.output is None:
        args.output = os.path.join(os.path.dirname(args.input), 'tags.json')

    with open(args.input, 'r') as fin:
        plugs = json.load(fin)

    tags = {}
    for plug in plugs:
        add_tags(tags, plug, plugs[plug]['tags'])

    with open(args.output, 'w') as fout:
        json.dump(tags, fout, sort_keys=True,
                  indent=2, separators=(',', ': '))


if __name__ == "__main__":
    main()
