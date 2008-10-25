#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More tests => 4;
use WWW::Contact;

my $wc = new WWW::Contact;

my $supplier = $wc->get_supplier_by_email('fayland@gmail.com');
is($supplier, 'Gmail', '$supplier OK');

$supplier = $wc->get_supplier_by_email('fayland@yahoo.com');
is($supplier, 'Yahoo', '$supplier OK');

$supplier = $wc->get_supplier_by_email('fayland@ymail.com');
is($supplier, 'Yahoo', '$supplier OK');

$supplier = $wc->get_supplier_by_email('fayland@rocketmail.com');
is($supplier, 'Yahoo', '$supplier OK');

1;