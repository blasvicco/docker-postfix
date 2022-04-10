#!/usr/bin/env python

import json
import os

MAIL_DOMAIN = os.environ.get('maildomain')
PATH = '/etc/resty-auto-ssl/storage/file/'
FILE_PATH = os.path.join(PATH, '{}%3Alatest'.format(MAIL_DOMAIN))
POSTFIX_CRT_PATH = '/etc/postfix/certs/'
FILE_KEY_PATH = os.path.join(POSTFIX_CRT_PATH, '{}.key'.format(MAIL_DOMAIN))
FILE_CRT_PATH = os.path.join(POSTFIX_CRT_PATH, '{}.crt'.format(MAIL_DOMAIN))

os.makedirs(POSTFIX_CRT_PATH, exist_ok=True)
with open(FILE_PATH) as ssl_file:
  data = json.load(ssl_file)
  key_content = data.get('privkey_pem')
  cert_content = data.get('fullchain_pem')

  with open(FILE_KEY_PATH, 'w+') as key_file:
    key_file.write(key_content)

  with open(FILE_CRT_PATH, 'w+') as crt_file:
    crt_file.write(cert_content)

