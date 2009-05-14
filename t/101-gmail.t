#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact;
use Data::Dumper;

# to avoid error like

=pod

t/103-rediff.....1/4
#   Failed test 'get error with wrong password'
#   at t/103-rediff.t line 33.
#          got: '500 Can't connect to mail.rediff.com:80 (connect: timeout)
# Content-Type: text/plain
# Client-Date: Tue, 28 Oct 2008 06:23:05 GMT
# Client-Warning: Internal response
#
500 Can't connect to mail.rediff.com:80 (connect: timeout)
# '
#     expected: 'Wrong Username or Password'
# Looks like you failed 1 test of 4.
t/103-rediff..... Dubious, test returned 1 (wstat 256, 0x100)
 Failed 1/4 subtests
        (less 2 skipped subtests: 1 okay)

=cut

BEGIN {
    unless ( $ENV{TEST_GMAIL} and $ENV{TEST_GMAIL_PASS} ) {
        plan skip_all => 'set $ENV{TEST_GMAIL} and $ENV{TEST_GMAIL_PASS} to test';
    }
    plan tests => 4;
}

my $wc = WWW::Contact->new();

my @contacts = $wc->get_contacts('fayland@gmail.com', 'pass');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Username or Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

{
    @contacts = $wc->get_contacts($ENV{TEST_GMAIL}, $ENV{TEST_GMAIL_PASS});
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with password');
    cmp_ok(scalar @contacts, '>', 0, 'get contact list');
    diag(Dumper(\@contacts));
}

1;