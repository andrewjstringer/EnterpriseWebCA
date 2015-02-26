#!/usr/bin/perl

#path to openssl
my $openssl = '/usr/bin/openssl';

my $csrfile = './filer04-csr.pem';

#decode csr
my $decodecsr = `$openssl req -in $csrfile -text -verify -noout`;

print "$decodecsr \n";


