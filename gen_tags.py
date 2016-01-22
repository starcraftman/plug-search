#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Module to re(generate) tags.json database.
Do NOT edit the tags.json file.
"""
from __future__ import absolute_import, print_function

import json
import os

ROOT = os.path.abspath(os.path.dirname(__file__))
if os.path.dirname(__file__) == '':
    ROOT = os.getcwd()


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
    with open(os.path.join(ROOT, 'db.json'), 'r') as fin:
        plugs = json.load(fin)

    tags = {}
    for plug in plugs:
        add_tags(tags, plug, plugs[plug]['tags'])

    with open(os.path.join(ROOT, 'tags.json'), 'w') as fout:
        json.dump(tags, fout, sort_keys=True, indent=2, separators=(',', ': '))


if __name__ == "__main__":
    main()
