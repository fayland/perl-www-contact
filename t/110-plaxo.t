#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact::Plaxo;
use Data::Dumper;

BEGIN {
    unless ( $ENV{TEST_PLAXO} and $ENV{TEST_PLAXO_PASS} ) {
        plan skip_all => 'set $ENV{TEST_PLAXO} and $ENV{TEST_PLAXO_PASS} to test';
    }
    plan tests => 4;
}

my $wc = WWW::Contact::Plaxo->new();

my @contacts = $wc->get_contacts('cpan@gmail.com', 'letmein', 'plaxo');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Username or Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

{
    @contacts = $wc->get_contacts($ENV{TEST_PLAXO}, $ENV{TEST_PLAXO_PASS}, 'plaxo');
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with username or password');
    cmp_ok(scalar @contacts, '>', 0, 'got contact list');
    diag(Dumper(\@contacts));
}
1;
