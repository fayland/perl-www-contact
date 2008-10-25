#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Contact' );
}

diag( "Testing WWW::Contact $WWW::Contact::VERSION, Perl $], $^X" );
