#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More;
use WWW::Contact;
use Data::Dumper;

BEGIN {
    plan skip_all => "author tests" unless (-e "$Bin/author.txt");
}

# sample author.txt (without '# ')
# tester_cpan@rediffmail.com      xxxx
# fayland@gmail.com               yyyy
# fayland@yahoo.com               zzzz 

open(my $fh, '<', "$Bin/author.txt");
local $/;
my $test = <$fh>;
close($fh);
my @tests = split(/\r?\n/, $test);

plan tests => scalar @tests * 2;

my $wc = WWW::Contact->new();

foreach my $t ( @tests ) {
    my ( $email, $pass ) = ( $t =~ /(\S+)\s+(\S+)/ );

    my @contacts = $wc->get_contacts($email, $pass);
    diag("test with $email and $pass");
    my $errstr = $wc->errstr;
    is($errstr, undef, '$email and $pass OK');
    cmp_ok(scalar @contacts, '>', 0, 'have contacts');
    diag(Dumper(\@contacts));
}

1;