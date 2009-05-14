#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::Contact;
use Data::Dumper;
use Term::ReadKey;

my $wc = WWW::Contact->new();

print "Email: ";
my $email = ReadLine(0);
chomp($email);
ReadMode('noecho'); 
print "Password: ";
my $pass  = ReadLine(0);
chomp($pass);
ReadMode 'normal';
unless ( $email and $pass ) {
    print "Please Enter Email and Password\n";
    exit 0;
}

print "\n\nWorking...\n\n";

my @contacts = $wc->get_contacts($email, $pass);
my $errstr   = $wc->errstr;
if ($errstr) {
    die $errstr;
} else {
    print Dumper(\@contacts);
}

1;