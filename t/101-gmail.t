#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact::Gmail;
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
    plan tests => 8;
}

my $wc = new WWW::Contact::Gmail;

my @contacts = $wc->get_contacts('fayland@gmail.com', 'pass');

# test get_contacts_from_html
open(my $fh, '<', "$Bin/samples/gmail.html");
local $/;
my $content = <$fh>;
close($fh);
my @contacts2 = $wc->get_contacts_from_html( $content );
is(scalar @contacts2, 3);
is_deeply(\@contacts2, [
    {
        name => 'fayland',
        email => 'yyyy@gmail.com'
    },
    {
        name => 'mailman',
        email => 'mailman@pm.org'
    },
    {
        name => 'support',
        email => 'support@pm.org'
    }
]);
open($fh, '<', "$Bin/samples/gmail_NoEmail.html");
local $/;
$content = <$fh>;
close($fh);
@contacts2 = $wc->get_contacts_from_html( $content );
is(scalar @contacts2, 3);
is_deeply(\@contacts2, [
    {
        name => 'fayland',
        email => 'yyyy@gmail.com'
    },
    {
        name => 'mailman',
        email => 'mailman@pm.org'
    },
    {
        name => 'support',
        email => 'support@pm.org'
    }
]);

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