#!/bin/bash
#written Andrew Stringer 13/02/2007
#extended 15/01/2009
#This is the menu to ease openssl signing etc.

BASEDIR=/opt/webca
OPENSSL='/usr/bin/openssl'
OPENSSLCNF="$BASEDIR/openssl/openssl.cnf"

MAIL='/usr/bin/heirloom-mailx'

CSRDIR="$BASEDIR/processroot/webuploads"
CERTDIR="$BASEDIR/processroot/webuploads"

#nothing below here should require editing.

#define functions
SignCSR() {
	clear
	echo -e '\E[37;44m' "\033[1mSign CSR  \033[0m"
	echo ' '
	ls -tr $CSRDIR | grep csr
	echo ' '
	echo -e -n '\E[37;44m' "\033[1mPlease enter CSR filename:- \033[0m"
	read CSRFILE

	CERTFILESUGGESTION=`basename ${CSRFILE} .csr`

	#parse uploaded list of CSR requests to extract originators email address
	CSREMAIL=`grep -w ${CSRFILE} receivedcsrlist.txt | cut -f2 -d,`

	CSR=`$OPENSSL req -in "$CSRDIR/$CSRFILE" -config $OPENSSLCNF -text -verify -noout`
	echo $CSR

	#sign here
	#get users input choice
	echo -e -n '\E[37;44m' "\033[1mSign Certificate? (y/n) \033[0m "
	read -n 1 SIGN
	echo

	case $SIGN in
	Y|y     )
		echo ' '
	        echo -e -n '\E[37;44m' "\033[1mPlease enter Certificate  filename:- \033[0m "
        	read -e -i "${CERTFILESUGGESTION}.cert" -p" " CERTFILE
		CERTFILE="${CERTFILE:-$CERTFILESUGGESTION.cert}"

		#FIXME - need to check if openssl signing was sucessful, if not bail out early.

		openssl ca -extensions usr_cert -notext -md sha256 -out $CERTDIR/$CERTFILE -config $OPENSSLCNF -infiles $CSRDIR/$CSRFILE &&

		#tighten certificate permission
		chmod o-r $CERTDIR/$CERTFILE &&
		chmod g-r $CERTDIR/$CERTFILE &&

		#copy signed certificate to openssl /cert store, uncomment for prod use
		cp $CERTDIR/$CERTFILE $BASEDIR/openssl/certs/

	        echo -e -n '\E[37;44m' "\033[1mPlease enter email to send certificate to:- \033[0m ${EMAIL}"
              	read -e -i "$CSREMAIL" -p" "  EMAIL
		EMAIL="${EMAIL:-$CSREMAIL}"


		echo "Certificate enclosed for ${CERTFILE} . " | \
		#$MAIL -a "$CERTDIR/$CERTFILE" -s "Certificate for $CERTFILE" "$EMAIL"
		echo "Please see attachment for your SSL certificate." | ${MAIL} -a "$CERTDIR/$CERTFILE" -r "ca@fmts.int" -s "Certificate for $CERTFILE" $EMAIL
                echo
                echo -e '\E[37;44m' "\033[1m - Certificate ${CERTFILE} emailed to ${EMAIL} - \033[0m"
                echo

		echo "${CERTFILE},${EMAIL}" >> issuedcertlist.txt


	;;

	N|n     )
		echo -n "Back to menu? "
		read DUMMY
                ;;

        *       ) echo "Invalid Selection"
                sleep 1
		;;
	esac


		echo -n "Back to menu? "
		read DUMMY

	return
#end of SignCSR() function
}

VerifyCSR() {
                clear
                echo -e '\E[37;44m' "\033[1mVerify CSR  \033[0m"
		echo ' '
		ls -tr $CSRDIR/ | grep csr
                echo ' '
                echo -e -n '\E[37;44m' "\033[1mPlease enter CSR filename to verify:- \033[0m"
		read CSRFILE
                echo "Your csr is $CSRFILE"
		CSR=`$OPENSSL req -in "$CSRDIR/$CSRFILE" -config $OPENSSLCNF -text -verify -noout`
		echo "$CSR"
		echo
		echo -n "Back to menu? "
		read DUMMY

}

ListCert() {
                clear
                echo -e '\E[37;44m' "\033[1mList Issued Certificates  \033[0m"
		echo ' '
		ls -tr $CERTDIR/ | grep cert | more
                echo ' '
		echo
		echo -n "Back to menu? "
		read DUMMY
}


EmailCert() {
                clear
                echo -e '\E[37;44m' "\033[1mEmail Issued Certificate  \033[0m"
                echo ' '
                ls -tr ${CERTDIR}/ | grep cert | more
                echo ' '
                echo -e -n '\E[37;44m' "\033[1mPlease enter Certificate  filename:- \033[0m"
                read CERTFILE

		CSREMAIL1=`grep -w ${CERTFILE} issuedcertlist.txt | cut -f2 -d,`
                echo -e -n '\E[37;44m' "\033[1mPlease enter email to send certificate to:- \033[0m"

		read -e -i "$CSREMAIL1" -p" "  EMAIL
                EMAIL="${EMAIL:-$CSREMAIL1}"


                echo "Please see attachment for your SSL certificate (${CERTFILE})." | ${MAIL} -a "${CERTDIR}/${CERTFILE}" -r "ca@fmts.int"  -s "Duplicate certificate for ${CERTFILE}" "${EMAIL}"

                echo
		echo -e '\E[37;44m' "\033[1m - Certificate ${CERTFILE} emailed to ${EMAIL} - \033[0m"
		echo
                echo -n "Back to menu? "
                read DUMMY

}



ExamineCert() {
		clear
		ls -tr $CERTDIR/ | grep cert | more
		echo
		echo -e -n '\E[37;44m' "\033[1mPlease enter Certificate name to examine:- \033[0m"
		read CERTFILE

		CERT=`$OPENSSL x509 -text -in "$CERTDIR/$CERTFILE" `
		echo "$CERT" | more
		echo ' '
		echo -n "Back to menu? "
		read DUMMY
}

ExamineCsr() {
                clear
                ls -tr $CERTDIR/ | grep csr | more
                echo
                echo -e -n '\E[37;44m' "\033[1mPlease enter Csr name to examine:- \033[0m"
                read CSRFILE

                CSR=`$OPENSSL req -in "$CERTDIR/$CSRFILE" -config $OPENSSLCNF -text -verify -noout`
                echo "$CSR" | more
                echo ' '
                echo -n "Back to menu? "
                read DUMMY

}


#end of functions

#write out menu
while [ 1 ]
do
clear
echo -e '\E[37;44m' "\033[1mCA Menu:- \033[0m"
echo -e '\E[37;44m' "\033[1m========= \033[0m"
echo

echo -e '\E[32;40m'  "\033[1mExamine [C]ert signing request file \033[0m"
echo -e '\E[32;40m'  "\033[1m[V]erify Cert signing request file \033[0m"
echo -e '\E[32;40m'  "\033[1m[S]ign CSR  \033[0m"
echo -e '\E[32;40m'  "\033[1m[L]ist Issued Certificates  \033[0m"
echo -e '\E[32;40m'  "\033[1m[E]xamine Certificate  \033[0m"
echo -e '\E[32;40m'  "\033[1mE[m]ail Certificate  \033[0m"
echo -e '\E[32;40m'  "\033[1m[R]evoke CSR  \033[0m"
echo -e '\E[32;40m'  "\033[1m[Q]uit  \033[0m"

echo ' '

#get users input choice
echo -e -n '\E[37;44m' "\033[1mPlease select an option letter:- \033[0m"
read -n 1 CHOICE
echo

#After we have some input, process it

case $CHOICE in
	C|c	)
		#call examine csr function
		ExamineCsr
		;;

        V|v     )
		#call verify function
		VerifyCSR
                ;;

	S|s     )
		#call CSR signing function
		SignCSR
                ;;


	L|l	)
		#list certificates
		ListCert
		;;

	E|e	)
		#examine certificate
		ExamineCert
		;;

        M|m     )
                #resend certificate by email
                EmailCert
                ;;

	R|r	)
		clear
		echo -e '\E[37;44m' "\033[1mRevoke CSR  \033[0m"
		echo
		echo "Not yet implemented"
		echo -n "Continue? "
		read DUMMY
		;;

        Q|q     )
                echo "Quitting."
		echo -n "Really? (y/n)"
		read QUIT
		case $QUIT in
	        Y|y     )
			exit 0
			;;
		*	)
			echo "Not quitting"
			;;
		esac
                ;;

        *       ) echo "Invalid Selection"
                sleep 1 ;;
esac
#end while do loop with done
done

exit 0

