package CPANPLUS::Dist::Gentoo;

use strict;
use warnings;

use File::Copy qw/copy/;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catdir catfile/;

use IPC::Cmd qw/run can_run/;

use CPANPLUS::Error;

use base qw/CPANPLUS::Dist::Base/;

=head1 NAME

CPANPLUS::Dist::Gentoo - CPANPLUS backend generating Gentoo ebuilds.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    cpan2dist --format=CPANPLUS::Dist::Gentoo \
              --dist-opts overlay=/usr/local/portage \
              --dist-opts distdir=/usr/portage/distfiles \
              --dist-opts manifest=yes \
              --dist-opts keywords=x86 \
              --dist-opts header="# Copyright 1999-2008 Gentoo Foundation" \
              --dist-opts footer="# End" \
              Any::Module You::Like

=head1 DESCRPITON

This module is a CPANPLUS backend that recursively generates Gentoo ebuilds for a given package in the specified overlay (defaults to F</usr/local/portage>), updates the manifest, and even emerges it (together with its dependencies) if the user requires it. You need write permissions on the directory where Gentoo fetches its source files (usually F</usr/portage/distfiles>). You also need to specify the correct keyword for your architecture if it differs from the default C<x86>.

The generated ebuilds are placed into the C<perl-gcpanp> category. They favour depending on C<perl-core>, C<dev-perl> or C<perl-gcpan> (in that order) rather than C<perl-gcpanp>.

=head1 INSTALLATION

After installing this module, you should append C<perl-gcpanp> to your F</etc/portage/categories> file.

=head1 METHODS

All the methods are inherited from L<CPANPLUS::Dist::Base>. Please refer to its documentation for precise information on what's done at each step.

=cut

use constant CATEGORY => 'perl-gcpanp';

sub format_available {
 for my $prog (qw/emerge ebuild/) {
  unless (can_run($prog)) {
   error "$prog is required to write ebuilds -- aborting";
   return 0;
  }
 }
 return 1;
}

sub init {
 my ($self) = @_;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 $stat->mk_accessors(qw/name version author dist desc uri src license deps
                        eb_name eb_version eb_dir eb_file fetched_arch
                        overlay distdir keywords do_manifest header footer
                        force verbose/);

 $stat->force($conf->get_conf('force'));
 $stat->verbose($conf->get_conf('verbose'));

 return 1;
}

my %gentooism = (
 'Digest'            => 'digest-base',
 'Locale-Maketext'   => 'locale-maketext',
 'Net-Ping'          => 'net-ping',
 'PathTools'         => 'File-Spec',
 'PodParser'         => 'Pod-Parser',
 'Set-Scalar'        => 'set-scalar',
 'Tie-EncryptedHash' => 'tie-encryptedhash',
);

sub prepare {
 my $self = shift;
 my $mod  = $self->parent;
 my $stat = $self->status;
 my $int  = $mod->parent;
 my $conf = $int->configure_object;

 my %opts = @_;

 my $keywords = delete $opts{'keywords'};
 $keywords = 'x86' unless defined $keywords;
 $keywords = [ split ' ', $keywords ];
 $stat->keywords($keywords);

 my $manifest = delete $opts{'manifest'};
 $manifest = 1 unless defined $manifest;
 $manifest = 0 if $manifest =~ /^\s*no?\s*$/i;
 $stat->do_manifest($manifest);

 my $header = delete $opts{'header'};
 if (defined $header) {
  1 while chomp $header;
  $header .= "\n\n";
 } else {
  $header = '';
 }
 $stat->header($header);

 my $footer = delete $opts{'footer'};
 if (defined $footer) {
  $footer = "\n" . $footer;
 } else {
  $footer = '';
 }
 $stat->footer($footer);

 $stat->overlay(delete($opts{'overlay'}) || '/usr/local/portage');

 $stat->distdir(delete($opts{'distdir'}) || '/usr/portage/distfiles');

 if ($stat->do_manifest && !-w $stat->distdir) {
  error 'distdir isn\'t writable -- aborting';
  return 0;
 }
 $stat->fetched_arch($mod->status->fetch);

 my $name = $mod->package_name;
 $stat->name($name);

 my $version = $mod->package_version;
 $stat->version($version);

 my $author = $mod->author->cpanid;
 $stat->author($author);

 $stat->dist($name . '-' . $version);

 $version =~ s/[^\d._]+//g;
 $version =~ s/^[._]*//;
 $version =~ s/[._]*$//;
 $version =~ s/[._]*_[._]*/_/g;
 {
  ($version, my $patch, my @rest) = split /_/, $version;
  $version .= '_p' . $patch if defined $patch;
  $version .= join('.', '', @rest) if @rest;
 }
 $stat->eb_version($version);

 $stat->eb_name($gentooism{$name} || $name);

 $stat->eb_dir(catdir($stat->overlay, CATEGORY, $stat->eb_name));

 my $file = catfile($stat->eb_dir,
                    $stat->eb_name . '-' . $stat->eb_version . '.ebuild');
 if (-e $file) {
  my $skip = 1;
  if ($stat->force) {
   if (-w $file) {
    1 while unlink $file;
    $skip = 0;
   } else {
    error "Can't force rewriting of $file -- skipping";
   }
  } else {
   msg 'Ebuild already generated for ' . $stat->dist . ' -- skipping';
  }
  if ($skip) {
   $stat->prepared(1);
   $stat->created(1);
   return 1;
  }
 }
 $stat->eb_file($file);

 $self->SUPER::prepare(%opts);

 my $desc = $mod->description;
 ($desc = $name) =~ s/-+/::/g unless $desc;
 $stat->desc($desc);

 $stat->uri('http://search.cpan.org/dist/' . $name);

 unless ($author =~ /^(.)(.)/) {
  error 'Wrong author name -- aborting';
  return 0;
 }
 $stat->src("mirror://cpan/modules/by-authors/id/$1/$1$2/$author/"
            . $mod->package);

 $stat->license([ qw/Artistic GPL-2/ ]);

 my $prereqs = $mod->status->prereqs;
 $prereqs = { map { ($gentooism{$_} || $_) => $prereqs->{$_} } keys %$prereqs };
 my @depends;
 for my $prereq (sort keys %$prereqs) {
  next if $prereq =~ /^perl(?:-|\z)/;
  my $obj = $int->module_tree($prereq);
  unless ($obj) {
   error 'Wrong module object -- aborting';
   return 0;
  }
  next if $obj->package_is_perl_core;
  {
   my $version;
   if ($prereqs->{$prereq}) {
    if ($obj->installed_version && $obj->installed_version < $obj->version) {
     $version = $obj->installed_version;
    } else {
     $version = $obj->package_version;
    }
   }
   push @depends, [ $obj , $version ];
  }
 }
 $stat->deps(\@depends);

 return 1;
}

sub create {
 my $self = shift;
 my $stat = $self->status;

 unless ($stat->prepared) {
  error 'Can\'t create ' . $stat->dist . ' since it was never prepared -- aborting';
  return 0;
 }

 if ($stat->created) {
  msg $stat->dist . ' was already created -- skipping';
  return 1;
 }

 $self->SUPER::create(@_);

 my $dir = $stat->eb_dir;
 unless (-d $dir) {
  eval { mkpath $dir };
  if ($@) {
   error "mkpath($dir): $@";
   return 0;
  }
 }

 my $d = $stat->header;
 $d   .= "# Generated by CPANPLUS::Dist::Gentoo version $VERSION\n\n";
 $d   .= 'MODULE_AUTHOR="' . $stat->author . "\"\ninherit perl-module\n\n";
 $d   .= 'S="${WORKDIR}/' . $stat->dist . "\"\n";
 $d   .= 'DESCRIPTION="' . $stat->desc . "\"\n";
 $d   .= 'HOMEPAGE="' . $stat->uri . "\"\n";
 $d   .= 'SRC_URI="' . $stat->src . "\"\n";
 $d   .= "SLOT=\"0\"\n";
 $d   .= 'LICENSE="|| ( ' . join(' ', sort @{$stat->license}) . " )\"\n";
 $d   .= 'KEYWORDS="' . join(' ', sort @{$stat->keywords}) . "\"\n";
 $d   .= 'DEPEND="' . join "\n",
  'dev-lang/perl',
  map {
   my $a = $_->[0]->package_name;
   my $x = '';
   if (defined $_->[1]) {
    $x  = '>=';
    $a .= '-' . $_->[1];
   }
   '|| ( ' . join(' ', map "$x$_/$a",
                           qw/perl-core dev-perl perl-gcpan/, CATEGORY)
           . ' )';
  } @{$stat->deps};
 $d   .= "\"\n";
 $d   .= "SRC_TEST=\"do\"\n";
 $d   .= $stat->footer;

 my $file = $stat->eb_file;
 open my $eb, '>', $file or do {
  error "open($file): $! -- aborting";
  return 0;
 };
 print $eb $d;
 close $eb;

 if ($stat->do_manifest) {
  unless (copy $stat->fetched_arch, $stat->distdir) {
   error "Couldn\'t copy the distribution file to distdir ($!) -- aborting";
   1 while unlink $file;
   return 0;
  }

  msg 'Adding Manifest entry for ' . $stat->dist;
  unless ($self->_run([ 'ebuild', $file, 'manifest' ], 0)) {
   1 while unlink $file;
   return 0;
  }
 }

 return 1;
}

sub install {
 my $self = shift;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 my $sudo = $conf->get_program('sudo');
 my @cmd = ('emerge', '=' . $stat->eb_name . '-' . $stat->eb_version);
 unshift @cmd, $sudo if $sudo;

 return $self->_run(\@cmd, 1);
}

sub uninstall {
 my $self = shift;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 my $sudo = $conf->get_program('sudo');
 my @cmd = ('emerge', '-C', '=' . $stat->eb_name . '-' . $stat->eb_version);
 unshift @cmd, $sudo if $sudo;

 return $self->_run(\@cmd, 1);
}

sub _run {
 my ($self, $cmd, $verbose) = @_;
 my $stat = $self->status;

 my ($success, $errmsg, $output) = do {
  local $ENV{PORTDIR_OVERLAY}     = $stat->overlay;
  local $ENV{PORTAGE_RO_DISTDIRS} = $stat->distdir;
  run command => $cmd, verbose => $verbose;
 };

 unless ($success) {
  error "$errmsg -- aborting";
  if (not $verbose and defined $output and $self->status->verbose) {
   my $msg = join '', @$output;
   1 while chomp $msg;
   error $msg;
  }
 }

 return $success;
}

=head1 DEPENDENCIES

Gentoo (L<http://gentoo.org>).

L<CPANPLUS>, L<IPC::Cmd> (core modules since 5.9.5).

L<File::Path> (since 5.001), L<File::Copy> (5.002), L<File::Spec::Functions> (5.00504).

=head1 SEE ALSO

L<cpan2dist>.

L<CPANPLUS::Dist::Base>, L<CPANPLUS::Dist::Deb>, L<CPANPLUS::Dist::Mdv>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-gentoo at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Gentoo>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::Gentoo

=head1 ACKNOWLEDGEMENTS

The module is to some extend cargo-culted from L<CPANPLUS::Dist::Deb> and L<CPANPLUS::Dist::Mdv>.

Kent Fredric, for testing and suggesting improvements.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo
