#!/usr/bin/bash
#sign ssl csr
#written Andrew Stringer 22/01/07 for Solaris

#test to see if file is given as input argument
if [ -z $2  ]
then
echo 'Useage:- verify.sh <csr-to-sign> <name-of-cert>'
exit 1
fi

#assume all if ok
/usr/sfw/bin/openssl ca -out $2 -config /etc/openssl/sb/openssl.cnf -infiles $1 &&

#tighten certificate permission
chmod o-r $2 &&
chmod g-r $2 &&

#copy signed certificate to openssl /cert store
cp $2 /etc/openssl/sb/certs

exit 0

