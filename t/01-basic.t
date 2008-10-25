#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More tests => 8;
use WWW::Contact;

my $wc = new WWW::Contact;

$wc->register_supplier( qr/\@a\.com$/, 'Unknown' );
$wc->register_supplier( 'b.com', 'Unknown' );

my @contacts = $wc->get_contacts('a@a.com', 'b');
my $errstr = $wc->errstr;
is($errstr, 'error!', 'get error with password b');
is(scalar @contacts, 0, 'empty contact list');

@contacts = $wc->get_contacts('a@b.com', 'c');
$errstr = $wc->errstr;
is($errstr, undef, 'no error with password c');
is(scalar @contacts, 2, 'get 2 contact list');

my $wc2 = new WWW::Contact::Unknown;
@contacts = $wc2->get_contacts('a@a.com', 'b');
$errstr = $wc2->errstr;
is($errstr, 'error!', 'get error with password b');
is(scalar @contacts, 0, 'empty contact list');

@contacts = $wc2->get_contacts('a@a.com', 'c');
$errstr = $wc2->errstr;
is($errstr, undef, 'no error with password c');
is(scalar @contacts, 2, 'get 2 contact list');

1;