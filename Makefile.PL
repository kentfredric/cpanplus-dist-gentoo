use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'CPANPLUS-Dist-Gentoo';

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/perl/modules/$dist.git",
 },
);

WriteMakefile(
    NAME             => 'CPANPLUS::Dist::Gentoo',
    AUTHOR           => 'Vincent Pit <perl@profvince.com>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/CPANPLUS/Dist/Gentoo.pm',
    ABSTRACT_FROM    => 'lib/CPANPLUS/Dist/Gentoo.pm',
    PL_FILES         => {},
    PREREQ_PM        => {
        'Carp'                  => 0,
        'CPANPLUS'              => 0,
        'Cwd'                   => 0,
        'File::Copy'            => 0,
        'File::Path'            => 0,
        'File::Spec::Functions' => 0,
        'IPC::Cmd'              => 0,
    },
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => \%META,
    dist             => {
        PREOP      => 'pod2text lib/CPANPLUS/Dist/Gentoo.pm > $(DISTVNAME)/README',
        COMPRESS   => 'gzip -9f', SUFFIX => 'gz'
    },
    clean            => {
        FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
    },
);
