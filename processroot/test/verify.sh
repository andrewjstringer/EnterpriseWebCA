#!/usr/bin/bash
#verify ssl csr
#written Andrew Stringer 22/01/07

#test to see if file is given as input argument
if [ -z $1 ]
then
echo 'Useage:- verify.sh <filename-to-verify>'
exit 1
fi

#assume all if ok
/usr/sfw/bin/openssl req -in $1 -config ../sb/openssl.cnf -text -verify -noout

exit 0

