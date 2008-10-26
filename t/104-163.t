#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact;
use Data::Dumper;
use WWW::Mechanize;

# test connection
BEGIN {
    my $wm = WWW::Mechanize->new(
        agent       => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        cookie_jar  => {},
        stack_depth => 1,
        timeout     => 60,
    );
    my $resp = $wm->get('http://www.google.com/');
    unless ( $resp->is_success ) {
        plan skip_all => "connection is not available";
    }
    plan tests => 4;
}

my $wc = new WWW::Contact;

my @contacts = $wc->get_contacts('fayland@163.com', 'pass');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

SKIP: {
    skip "set ENV TEST_163 and TEST_163_PASS to test real", 2
        unless ( $ENV{TEST_163} and $ENV{TEST_163_PASS} );

    @contacts = $wc->get_contacts($ENV{TEST_163}, $ENV{TEST_163_PASS});
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with password');
    cmp_ok(scalar @contacts, '>', 0, 'get contact list');
    diag(Dumper(\@contacts));
}

1;