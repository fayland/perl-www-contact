#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More tests => 10;
use WWW::Contact;

my $wc = WWW::Contact->new();

my $supplier = $wc->get_supplier_by_email('fayland@gmail.com');
is($supplier, 'Gmail');

$supplier = $wc->get_supplier_by_email('fayland@yahoo.com');
is($supplier, 'Yahoo');

$supplier = $wc->get_supplier_by_email('fayland@ymail.com');
is($supplier, 'Yahoo');

$supplier = $wc->get_supplier_by_email('fayland@rocketmail.com');
is($supplier, 'Yahoo');

$supplier = $wc->get_supplier_by_email('fayland@rediffmail.com');
is($supplier, 'Rediffmail');

$supplier = $wc->get_supplier_by_email('fayland@163.com');
is($supplier, 'CN::163');
$supplier = $wc->get_supplier_by_email('fayland@netease.com');
is($supplier, 'CN::163');
$supplier = $wc->get_supplier_by_email('fayland@popo.163.com');
is($supplier, 'CN::163');
$supplier = $wc->get_supplier_by_email('fayland@yeah.net');
is($supplier, 'CN::163');

$supplier = $wc->get_supplier_by_email('fayland@aol.com');
is($supplier, 'AOL');

1;