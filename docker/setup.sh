#!/bin/sh

# creating files and directories
mkdir -p /etc/opendkim/domainkey/
mkdir -p /etc/postfix/sasl/
mkdir -p /run/opendkim
touch /etc/postfix/main.cf
touch /etc/postfix/master.cf
touch /etc/postfix/sasl/smtpd.conf

########################
#  Setting up SASL DB  #
########################
while IFS=':' read -r _domain _user _pwd _cannonical; do
  echo $_pwd | saslpasswd2 -p -c -u $_domain $_user
done < /tmp/passwd
chown postfix:postfix /etc/sasldb2

########################
#  Setting up Postfix  #
########################
postconf -e myhostname=$maindomain
postconf -F '*/*/chroot = n'

############
# The following options set parameters needed by Postfix to enable
# Cyrus-SASL support for authentication of mail clients.
############
# smtpd.conf
cat >> /etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF
# /etc/postfix/main.cf
postconf -e smtpd_sasl_auth_enable=yes
postconf -e broken_sasl_auth_clients=yes
postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination

######################
# Enable TLS and SSL #
######################
./parse_resty_auto_ssl.py
postmap -F lmdb:/etc/postfix/ssl_map
if [[ -n "/etc/postfix/certs/$maindomain.key" && -n "/etc/postfix/certs/$maindomain.crt" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_key_file=/etc/postfix/certs/$maindomain.key
  postconf -e smtpd_tls_cert_file=/etc/postfix/certs/$maindomain.crt
  postconf -e smtpd_tls_protocols=TLSv1.2,TLSv1.1,!TLSv1,!SSLv2,!SSLv3
  postconf -e smtp_tls_protocols=TLSv1.2,TLSv1.1,!TLSv1,!SSLv2,!SSLv3
  postconf -e smtpd_tls_ciphers=high
  postconf -e smtp_tls_ciphers=high
  postconf -e smtpd_tls_mandatory_protocols=TLSv1.2,TLSv1.1,!TLSv1,!SSLv2,!SSLv3
  postconf -e smtp_tls_mandatory_protocols=TLSv1.2,TLSv1.1,!TLSv1,!SSLv2,!SSLv3
  postconf -e smtpd_tls_mandatory_ciphers=high
  postconf -e smtp_tls_mandatory_ciphers=high
  postconf -e smtpd_tls_mandatory_exclude_ciphers=MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL
  postconf -e smtp_tls_mandatory_exclude_ciphers=MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL
  postconf -e smtpd_tls_exclude_ciphers=MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL
  postconf -e smtp_tls_exclude_ciphers=MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL
  postconf -e smtpd_tls_security_level=encrypt
  postconf -e smtp_tls_security_level=encrypt
  postconf -e smtpd_tls_loglevel=2
  postconf -e smtp_tls_loglevel=2
  postconf -e tls_preempt_cipherlist=yes
  postconf -e tls_server_sni_maps=lmdb:/etc/postfix/ssl_map
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"

  postconf -M smtps/inet="smtps   inet   n   -   n   -   -   smtpd"
  postconf -P "smtps/inet/syslog_name=postfix/smtps"
fi

###############################
# Setting up sender canonical #
###############################
while IFS=':' read -r _domain _user _pwd _cannonical; do
  echo "/$_cannonical/ $_user" >> /etc/postfix/sender_canonical
  echo "/From:$_cannonical/ REPLACE From: $_user" >> /etc/postfix/header_checks
done < /tmp/passwd

postconf -e sender_canonical_classes=envelope_sender,header_sender
postconf -e sender_canonical_maps=regexp:/etc/postfix/sender_canonical
postconf -e smtp_header_checks=regexp:/etc/postfix/header_checks

#####################
# Setting up loggin #
#####################
postconf -e maillog_file=/var/log/postfix.log
postconf -e maillog_file_permissions=0644

##############
#  opendkim  #
##############
# /etc/postfix/main.cf
postconf -e milter_protocol=2
postconf -e milter_default_action=accept
postconf -e smtpd_milters=inet:localhost:12301
postconf -e non_smtpd_milters=inet:localhost:12301

cat >> /etc/opendkim/opendkim.conf <<EOF
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost
EOF

cat >> /etc/opendkim/TrustedHosts <<EOF
127.0.0.1
localhost
192.168.0.1/24
EOF

OLDIFS=$IFS
IFS=','
for domain in $maildomains; do
  echo "*.$domain" >> /etc/opendkim/TrustedHosts
  echo "mail._domainkey.$domain $domain:mail:/etc/opendkim/domainkey/$domain.private" >> /etc/opendkim/KeyTable
  echo "*@$domain mail._domainkey.$domain" >> /etc/opendkim/SigningTable
  if [ ! -f /etc/opendkim/domainkey/$domain.private ]; then
    opendkim-genkey -b 1024 -d $domain -D /etc/opendkim/domainkey -s $domain -v
    chown opendkim:opendkim /etc/opendkim/domainkey/$domain.private
    chmod 400 /etc/opendkim/domainkey/$domain.private
  fi
done
IFS=$OLDIFS
