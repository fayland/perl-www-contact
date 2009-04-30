#!/usr/bin/perl

use strict;
use warnings;

###################################
# a daily cron to test if something breaks down
# USAGE:
#   cron_to_test.pl
#   gmail_account.txt   - send email from, so perl-www-contact can get the report
#   test_accounts.txt   - the test accounts
#
# Sample:
#
#   gmail_account.txt (without '# ')
# fayland@gmail.com     password
#
#   test_accounts.txt (without '# '), each line contains email and password
# test_account@gmail.com        password
# tester_cpan@rediffmail.com    password
# tester_cpan@@yahoo.com        password

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

-e "$Bin/gmail_account.txt" or die "Can't send the report, please create gmail_account.txt\n";
-e "$Bin/test_accounts.txt" or die "No test accounts since no test_accounts.txt\n";

use WWW::Contact;
use Email::Send;
use Email::Simple::Creator;

my $is_broken = 0;
my $body = "Test WWW::Contact $WWW::Contact::VERSION\n\n";

my $wc = WWW::Contact->new();

open(my $fh, '<', "$Bin/test_accounts.txt") or die $!;
local $/;
my $test_accounts = <$fh>;
close($fh);

my @lines = split(/\r?\n/, $test_accounts);
foreach my $line ( @lines ) {
    my ( $email, $pass ) = ( $line =~ /(\S+)\s+(\S+)/ );
    
    my @contacts = $wc->get_contacts($email, $pass);
    my $errstr = $wc->errstr;
    if ( $errstr or scalar @contacts == 0 ) {
        $body .= "$email is broken I guess, please check it manually.\n\n";
        $is_broken = 1;
    } else {
        $body .= "$email [OK]\n\n";
    }
}

if ( $is_broken ) {
    print STDERR $body;
    
    # get mail account
    open(my $fh2, '<', "$Bin/gmail_account.txt");
    my $mail_info = <$fh2>;
    close($fh2);
    my ($email, $pass) = ( $mail_info =~ /(\S+)\s+(\S+)/ );
    
    my $mailer = Email::Send->new( {
        mailer => 'SMTP::TLS',
        mailer_args => [
            Host => 'smtp.gmail.com',
            Port => 587,
            User => $email,
            Password => $pass,
            Hello => 'fayland.org',
        ]
    } );

    my $es = Email::Simple->create(
        header => [
            From    => $email,
            To      => 'perl-www-contact@googlegroups.com',
            Subject => "Report on WWW-Contact $WWW::Contact::VERSION " . scalar(localtime()),
        ],
        body => $body,
    );
    
    eval { $mailer->send($es) };
    die "Error sending email: $@" if $@;
}

1;