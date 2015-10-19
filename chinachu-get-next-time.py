#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ------------------------------------------------------- #
#
# chinachu-get-next-time.py
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

import argparse
import io
import json
import time
from urllib.request import urlopen

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Get the start time of the next reserved program from Chinachu in the form of UNIX time')
	parser.add_argument('url', type=str, help='url string (example: http://localhost:10772)')
	args = parser.parse_args()

	response = urlopen(args.url + '/api/reserves.json')
	res = json.load(io.TextIOWrapper(response, response.getheader('content-type').split('charset=')[1]))
	now = time.time()
	for e in [ int(ent['start'] / 1000) for ent in res if ent['start'] / 1000 > now]:
		print(e)
		break

