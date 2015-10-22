#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ------------------------------------------------------- #
#
# chinachu-api-is-recording.py
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

import argparse
import io
import json
import sys
import time
from urllib.request import urlopen

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Get the recording status of Chinachu')
	parser.add_argument('url', type=str, help='url string (example: http://localhost:10772)')
	args = parser.parse_args()

	response = urlopen(args.url + '/api/recording.json')
	res = json.load(io.TextIOWrapper(response, response.getheader('content-type').split('charset=')[1]))
	if len(res) > 0:	# Chinachu is recording.
		sys.exit(0)
	sys.exit(1)
