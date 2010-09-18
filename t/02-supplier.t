#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::More;
use WWW::Contact;

my $wc = WWW::Contact->new();

my $supplier = $wc->get_supplier_by_email('fayland@gmail.com');
is($supplier, 'GoogleContactsAPI');

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

$supplier = $wc->get_supplier_by_email('kdm@dcp24.ru');
is($supplier, 'GoogleContactsAPI');

$supplier = $wc->get_supplier_by_email('pimenov@uplifto.ru');
is($supplier, 'GoogleContactsAPI');

$supplier = $wc->get_supplier_by_email('pimenov@uplifto.ru');
is($supplier, 'GoogleContactsAPI');

my $r = $wc->resolve;
is(scalar keys %$r, 2);
is($r->{'uplifto.ru'}, 'GoogleContactsAPI');
is($r->{'dcp24.ru'  }, 'GoogleContactsAPI');

done_testing();

1;