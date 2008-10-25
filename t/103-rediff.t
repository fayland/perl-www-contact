#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
use WWW::Contact::Rediffmail;
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
    my $resp = $wm->get('http://www.rediff.com/');
    unless ( $resp->is_success ) {
        plan skip_all => "connection is not available";
    }
    plan tests => 4;
}

my $wc = new WWW::Contact::Rediffmail->new();

my @contacts = $wc->get_contacts('cpan@rediffmail.com', 'letmein');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Username or Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

SKIP: {
    skip "set ENV TEST_REDIFF and TEST_REDIFF_PASS to test real", 2
        unless ( $ENV{TEST_REDIFF} and $ENV{TEST_REDIFF_PASS} );

    @contacts = $wc->get_contacts($ENV{TEST_REDIFF}, $ENV{TEST_REDIFF_PASS});
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with username or password');
    cmp_ok(scalar @contacts, '>', 0, 'got contact list');
    diag(Dumper(\@contacts));
}
1;