#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'CPANPLUS::Dist::Gentoo' );
}

diag( "Testing CPANPLUS::Dist::Gentoo $CPANPLUS::Dist::Gentoo::VERSION, Perl $], $^X" );
