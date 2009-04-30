#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact;
use Data::Dumper;

BEGIN {
    unless ( $ENV{TEST_AOL} and $ENV{TEST_AOL_PASS} ) {
        plan skip_all => 'set $ENV{TEST_AOL} and $ENV{TEST_AOL_PASS} to test';
    }
    plan tests => 4;
}

my $wc = WWW::Contact->new();

my @contacts = $wc->get_contacts('fayland@aol.com', 'letmein');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Username or Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

{
    @contacts = $wc->get_contacts($ENV{TEST_AOL}, $ENV{TEST_AOL_PASS});
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with password');
    cmp_ok(scalar @contacts, '>', 0, 'get contact list');
    diag(Dumper(\@contacts));
}

1;