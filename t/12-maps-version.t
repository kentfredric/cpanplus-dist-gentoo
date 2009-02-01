#!perl -T

use strict;
use warnings;

use Test::More tests => 10 + 24;

use CPANPLUS::Dist::Gentoo::Maps;

*vc2g  = \&CPANPLUS::Dist::Gentoo::Maps::version_c2g;

is vc2g('1'),       '1',      "version_c2g('1')";
is vc2g('a1b'),     '1',      "version_c2g('a1b')";
is vc2g('..1'),     '1',      "version_c2g('..1')";
is vc2g('1.0'),     '1.0',    "version_c2g('1.0')";
is vc2g('1._0'),    '1.0',    "version_c2g('1._0')";
is vc2g('1_1'),     '1_p1',   "version_c2g('1_1')";
is vc2g('1_.1'),    '1_p1',   "version_c2g('1_.1')";
is vc2g('1_.1._2'), '1_p1.2', "version_c2g('1_.1._2')";
is vc2g('1_.1_2'),  '1_p1.2', "version_c2g('1_.1_2')";
is vc2g('1_.1_.2'), '1_p1.2', "version_c2g('1_.1_.2')";

*vgcmp = \&CPANPLUS::Dist::Gentoo::Maps::version_gcmp;

eval { vgcmp('dongs', 1) };
like $@, qr/Couldn't\s+parse\s+version\s+string/, "version_gcmp('dongs', 1)";

eval { vgcmp(1, 'dongs') };
like $@, qr/Couldn't\s+parse\s+version\s+string/, "version_gcmp(1, 'dongs')";

is vgcmp(undef, 0), 0,  'version_gcmp(undef, 0)';
is vgcmp(0, 0),     0,  'version_gcmp(0, 0)';
is vgcmp(1, 0),     1,  'version_gcmp(1, 0)';
is vgcmp(0, 1),     -1, 'version_gcmp(0, 1)';
is vgcmp(1, 1),     0,  'version_gcmp(1, 1)';

is vgcmp('1.0', 1),     0,  "version_gcmp('1.0', 1)";
is vgcmp('1.1', 1),     1,  "version_gcmp('1.1', 1)";
is vgcmp('1.1', '1.0'), 1,  "version_gcmp('1.1', '1.0')";
is vgcmp(1, '1.0'),     0,  "version_gcmp(1, '1.0')";
is vgcmp(1, '1.1'),     -1, "version_gcmp(1, '1.1')";
is vgcmp('1.0', '1.1'), -1, "version_gcmp('1.0', '1.1')";

is vgcmp('1.0_p0', '1.0_p0'),     0,  "version_gcmp('1.0_p0', '1.0_p0')";
is vgcmp('1.0_p0', '1.0_p1'),     -1, "version_gcmp('1.0_p0', '1.0_p1')";
is vgcmp('1.1_p0', '1.0_p1'),     1,  "version_gcmp('1.1_p0', '1.0_p1')";
is vgcmp('1.1_p0', '1.1_p0.1'),   -1, "version_gcmp('1.1_p0', '1.1_p0.1')";
is vgcmp('1.1_p0.1', '1.1_p0.1'), 0,  "version_gcmp('1.1_p0.1', '1.1_p0.1')";

is vgcmp('1.2_p0-r0', '1.2_p0'),  0,  "version_gcmp('1.2_p0-r0', '1.2_p0')";
is vgcmp('1.2_p0-r1', '1.2_p0'),  1,  "version_gcmp('1.2_p0-r1', '1.2_p0')";
is vgcmp('1.2-r0',    '1.2_p0'),  0,  "version_gcmp('1.2-r0', '1.2_p0')";
is vgcmp('1.2-r1',    '1.2_p0'),  1,  "version_gcmp('1.2-r1', '1.2_p0')";
is vgcmp('1.2-r1',    '1.2_p1'),  -1, "version_gcmp('1.2-r1', '1.2_p1')";
is vgcmp('1.2-r2',    '1.2_p1'),  -1, "version_gcmp('1.2-r2', '1.2_p1')";
