#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use WWW::Contact;
use Data::Dumper;

my $wc = WWW::Contact->new();

$wc->known_supplier->{'gmail.com'} = 'GoogleContactsAPI';
my @contacts = $wc->get_contacts($ENV{TEST_CONTACT}, $ENV{TEST_CONTACT_PASS});
my $errstr   = $wc->errstr;
if ($errstr) {
    die $errstr;
} else {
    print Dumper(\@contacts);
}

1;