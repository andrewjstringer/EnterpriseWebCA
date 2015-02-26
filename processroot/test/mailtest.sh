#!/bin/bash

NAIL='/usr/local/bin/nail'
CSR='filer04-csr.pem'
CSRFILE="Certificate for $CSR "
EMAIL='me@example.gov.uk'

SERVER='myserver.gov.pri'

eval "echo `cat mailbody.txt `" > $NAIL -a "../webuploads/$CSR"  -s "$CSRFILE" "$EMAIL"

