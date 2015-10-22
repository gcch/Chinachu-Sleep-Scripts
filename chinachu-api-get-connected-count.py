#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ------------------------------------------------------- #
#
# chinachu-api-get-connected-count.py
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
	parser = argparse.ArgumentParser(description='Get the number of users connecting to Chinachu')
	parser.add_argument('url', type=str, help='url string (example: http://localhost:10772)')
	args = parser.parse_args()

	response = urlopen(args.url + '/api/status.json')
	res = json.load(io.TextIOWrapper(response, response.getheader('content-type').split('charset=')[1]))
	print(res['connectedCount'])
