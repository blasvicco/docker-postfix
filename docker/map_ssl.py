#!/usr/bin/env python3

import json
import os

# constants
DOMAINS = os.environ.get('maildomains').split(',')
DOMAIN_MAP = os.path.join(os.sep, 'etc', 'postfix', 'ssl_map')
PATH = os.path.join(os.sep, 'etc', 'letsencrypt', 'live')

# open a file to write the mapping
with open(DOMAIN_MAP, 'w+') as mapping:
  # loop per domain
  for domain in DOMAINS:
    # write the domain, key and crt
    privkey_pem = os.path.join(PATH, domain, 'privkey.pem')
    fullchain_pem = os.path.join(PATH, domain, 'fullchain.pem')
    mapping.write(f'{domain} {privkey_pem} {fullchain_pem}\n')
