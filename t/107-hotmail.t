#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;
use WWW::Contact::Hotmail;
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
    my $resp = $wm->get('http://www.mail.com/');
    unless ( $resp->is_success ) {
        plan skip_all => "connection is not available";
    }
    plan tests => 6;
}

my $wc = new WWW::Contact::Hotmail->new();

# test get_contacts_from_html
open(my $fh, '<', "$Bin/samples/hotmail.html");
local $/;
my $content = <$fh>;
close($fh);
my @contacts2 = $wc->get_contacts_from_html( $content );
is(scalar @contacts2, 2);
is_deeply(\@contacts2, [
    {
        name => 'fayland xxx',
        email => 'xxxx@gmail.com'
    },
    {
        name => 'fayland lam',
        email => 'zzz@gmail.com'
    }
]);

my @contacts = $wc->get_contacts('cpan@hotmail.com', 'pass');
my $errstr = $wc->errstr;
is($errstr, 'Wrong Password', 'get error with wrong password');
is(scalar @contacts, 0, 'empty contact list');

SKIP: {
    skip "set ENV TEST_HOTMAIL and TEST_HOTMAIL_PASS to test real", 2
        unless ( $ENV{TEST_HOTMAIL} and $ENV{TEST_HOTMAIL_PASS} );

    @contacts = $wc->get_contacts($ENV{TEST_HOTMAIL}, $ENV{TEST_HOTMAIL_PASS});
    $errstr = $wc->errstr;
    is($errstr, undef, 'no error with password');
    cmp_ok(scalar @contacts, '>', 0, 'get contact list');
    diag(Dumper(\@contacts));
}

1;
