#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use CPANPLUS::Dist::Gentoo::Maps;

our %gentooisms;
*gentooisms = \%CPANPLUS::Dist::Gentoo::Maps::gentooisms;

is scalar(keys %gentooisms), 71, 'gentooisms are all there';

is $gentooisms{PathTools}, 'File-Spec', 'gentooisms were correctly loaded';

is CPANPLUS::Dist::Gentoo::Maps::name_c2g('PathTools'), 'File-Spec', 'name_c2g maps gentooisms correctly';

is CPANPLUS::Dist::Gentoo::Maps::name_c2g('CPANPLUS-Dist-Gentoo'), 'CPANPLUS-Dist-Gentoo', 'name_c2g returns non gentooisms correctly';
