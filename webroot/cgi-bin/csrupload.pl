#!/usr/bin/perl
#Written Andrew Stringer starting 01/12/06
#Last revised, Andrew Stringer, 03/11/2014

#This receives a certificate signing request (csr) from a web page
#and checks syntax for correct fields.
#This file is then saved to a directory in the openssl ca structure.

# see http://www.hut.fi/u/jkorpela/forms/testing.html
# and http://cgi-lib.berkeley.edu/ex/simple-form.cgi.txt


sub ERROR
#write an error and quit if incorrect info supplied.
{
my $errorfield = shift ;
#print http header
print "Content-type: text/html\n\n";
print <<ENDOFTEXTs1 ;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>FMTS Web CA CSR upload  **Error detected**</title>
</head>
<body>

<table border="1">
<tr><td bgcolor="#eeeeee">$errorfield Please use the back button in your browser and correct the error.</td></tr>
</table>

</body>
</html>
ENDOFTEXTs1

#terminate program, do not return to calling MAIN:
exit (1) ;
}



MAIN:
{
use CGI;
use strict;
use warnings;

use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;

#path to openssl
#my $openssl = '/opt/webca/openssl';
my $openssl = '/usr/bin/openssl';
my $opensslcnf = '/opt/webca/openssl/openssl.cnf';
my $csrfilepath = '/opt/webca/processroot/webuploads';
my $receivedcsrlist = '/opt/webca/processroot/receivedcsrlist.txt';

my $domain = '.fmts.int';

#for emailing notifications
my $mailer = '/usr/sbin/exim4';
my $caemail1 = 'astringer@friendmts.com';
my $caemail2 = '';

my $fqdn = '';

#read in values from cgi
my $cgi = new CGI;

my $username = $cgi->param('username');
my $phonenumber = $cgi->param('phone');
my $email = $cgi->param('email');
my $servername = $cgi->param('servername');
my $csrfile = $cgi->param('csrfile');
my $csrfilehandle = $cgi->param('csrfile');

#declare some variables
my $namevalid;
my $phonenumbervalid;
my $emailvalid;
my $servernamevalid;
my $fileexists;
my $csrinvalid;
my $csrfilevalid;

my $safe_filename_characters = "a-zA-Z0-9_.-";

#start checking to catch invalid / unsafe input
#1st do name, check if blank
if ($username eq '')
        {
        $namevalid="0";
        ERROR("You do not seem to have supplied a contact name. ");
        }
#check if unsafe characters
if ($username=~m/[^a-zA-Z0-9\-\ \']/)
        {
        $namevalid="0";
        ERROR("Your contact name contains illegal characters. ");
        }

#check phone number
if ($phonenumber eq '')
        {
        $phonenumbervalid="0";
        ERROR("You do not seem to have supplied a telephone number. ");
        }
#Check if it contains anything other than numbers or space
if ($phonenumber=~m/[^0-9 \ ]/)
        {
        $phonenumbervalid="0";
        ERROR("Your telephone number contains letters, only numbers are allowed. ");
        }
#check if number is too short or long
if ((length $phonenumber) < 11)
        {
        $phonenumbervalid="0";
        ERROR("Your telephone number is too short, please use the format 0121 303 xxxx. ");
        }
if ((length $phonenumber) > 13)
        {
        $phonenumbervalid="0";
        ERROR("Your telephone number is too long, please use the format 0121 303 xxxx. ");
        }


#Check email address for validity
if ($email eq '')
        {
        $emailvalid="0";
        ERROR("You do not seem to have supplied an email address. ");
        }
#check if unsafe characters
if ($email=~m/[^a-zA-Z0-9\-@\.\']/)
        {
        $emailvalid="0";
        ERROR("Your email address contains illegal characters. ");
        }
#check if it contains an @
if ($email=~m/^@/)
        {
        $emailvalid="0";
        ERROR("Your email address does not contain an &at;. ");
        }




#check servername is valid
if ($servername eq '')
        {
        $servernamevalid="0";
        ERROR("You do not seem to have supplied a server name. ");
        }
else
        {
        $servernamevalid="1";
        }

#convert to lower case
$servername=~tr/A-Z/a-z/ ;

if ($servername=~m/[^a-z0-9\-\.]/)
        {
        $servernamevalid="0";
        ERROR("Your server name contains illegal characters. ");
        }
else
        {
#append suffix
        $fqdn = $servername.$domain;
        $servernamevalid="1";
        }

#Check CSR file namefor length
if ( !$csrfile)
        {
        $csrfilevalid="0";
        ERROR("Your CSR file is invalid or not specified. ");
        }

#strip any path info from the csrfile name
my ( $name, $path, $extension ) = fileparse ( $csrfile, '..*' );
$csrfile = $name . $extension;

$csrfile =~ tr/ /_/;
$csrfile =~ s/[^$safe_filename_characters]//g;

if ( $csrfile =~ /^([$safe_filename_characters]+)$/ )
	{
	$csrfile = $1;
	}
else
	{
	ERROR("Your CSR file is invalid or not specified. ");
	}


#write out csr to file system
#test if we are going to overwrite a file,
#check for other than zero size.

#Get filehandle 
my $csrfilehandle = $cgi->upload("csrfile");


if (-s "$csrfilepath/$csrfile")
{
        $fileexists="0";
        ERROR("A file of this name already exists, please choose another name. ");
}
else
{
        umask 0377;
        open (OUTFILE,">$csrfilepath/$csrfile");
	binmode OUTFILE;
        while (<$csrfilehandle>)
        {
        print OUTFILE ;
        }
        close OUTFILE;

	
	open (CSRLIST,">>$receivedcsrlist");
	print CSRLIST "$username,$email,$phonenumber,$servername,$csrfilehandle\n";
	close CSRLIST;
}


#decode csr
#pipe stderr to stdout so we can see any errors
my $decodecsr = `$openssl req -in $csrfilepath/$csrfile -text -verify -noout 2>&1`;
#-config $opensslcnf
if ($decodecsr =~ m/unable to load X509 request/)
        {
        $csrinvalid="1";
        `rm $csrfilepath/$csrfile`;
        ERROR("Your csr file seems to be invalid, openssl reports <pre>$decodecsr</pre><br>");
        }


#mail info to CA user
open MAIL,"|$mailer";

print MAIL <<ConfirmEMAIL;
From: webca\@inet01.fmts.int
To: $caemail1
Cc: $caemail2
Subject: CSR received for $fqdn from $email

A csr has been uploaded for $fqdn by $email to $csrfilepath/$csrfile.


$decodecsr


ConfirmEMAIL
close MAIL;



#start writing out html page
#print header
print "Content-type: text/html\n\n";
print <<ENDOFTEXT10 ;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<body>

<br>
Your Certificate Signing Request has been uploaded sucessfully and the contents are shown
below:-

ENDOFTEXT10

print "<pre>\n";
print "$decodecsr \n";
print "</pre>\n";


#End of program
}
exit (0);

