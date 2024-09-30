#!/usr/bin/env python

import json
import os

# constants
DOMAINS = os.environ.get('maildomains').split(',')
DOMAIN_MAP = os.path.join(os.sep, 'etc', 'postfix', 'ssl_map')
PATH = os.path.join(os.sep, 'etc', 'resty-auto-ssl', 'storage', 'file')
POSTFIX_CRT_PATH = os.path.join(os.sep, 'etc', 'postfix', 'certs')

# open a file to write the mapping
with open(DOMAIN_MAP, 'w+') as mapping:

  # loop per domain
  for domain in DOMAINS:

    file_path = os.path.join(PATH, f'{domain}%3Alatest')
    file_key_path = os.path.join(POSTFIX_CRT_PATH, f'{domain}.key')
    file_crt_path = os.path.join(POSTFIX_CRT_PATH, f'{domain}.crt')

    # write the domain, key and crt
    mapping.write(f'{domain} {file_key_path} {file_crt_path}\n')

    os.makedirs(POSTFIX_CRT_PATH, exist_ok=True)
    with open(file_path) as ssl_file:
      data = json.load(ssl_file)
      key_content = data.get('privkey_pem')
      cert_content = data.get('fullchain_pem')

      with open(file_key_path, 'w+') as key_file:
        key_file.write(key_content)

      with open(file_crt_path, 'w+') as crt_file:
        crt_file.write(cert_content)

