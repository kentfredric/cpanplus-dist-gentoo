package CPANPLUS::Dist::Gentoo;

use strict;
use warnings;

use Cwd qw/abs_path/;
use File::Copy qw/copy/;
use File::Path qw/mkpath/;
use File::Spec::Functions qw/catdir catfile/;

use IPC::Cmd qw/run can_run/;
use version;

use CPANPLUS::Error;

use base qw/CPANPLUS::Dist::Base/;

=head1 NAME

CPANPLUS::Dist::Gentoo - CPANPLUS backend generating Gentoo ebuilds.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

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

This module is a CPANPLUS backend that recursively generates Gentoo ebuilds for a given package in the specified overlay (defaults to F</usr/local/portage>), updates the manifest, and even emerges it (together with its dependencies) if the user requires it. You need write permissions on the directory where Gentoo fetches its source files (usually F</usr/portage/distfiles>). The valid C<KEYWORDS> for the generated ebuilds are by default those given in C<ACCEPT_KEYWORDS>, but you can specify your own with the C<keywords> dist-option.

The generated ebuilds are placed into the C<perl-gcpanp> category. They favour depending on a C<virtual>, on C<perl-core>, C<dev-perl> or C<perl-gcpan> (in that order) rather than C<perl-gcpanp>.

=head1 INSTALLATION

After installing this module, you should append C<perl-gcpanp> to your F</etc/portage/categories> file.

=head1 METHODS

All the methods are inherited from L<CPANPLUS::Dist::Base>. Please refer to its documentation for precise information on what's done at each step.

=cut

use constant CATEGORY => 'perl-gcpanp';

my $overlays;
my $default_keywords;
my $default_distdir;
my $main_portdir;

sub _unquote {
 my $s = shift;
 $s =~ s/^["']*//;
 $s =~ s/["']*$//;
 return $s;
}

sub format_available {
 for my $prog (qw/emerge ebuild/) {
  unless (can_run($prog)) {
   error "$prog is required to write ebuilds -- aborting";
   return 0;
  }
 }

 if (IPC::Cmd->can_capture_buffer) {
  my ($success, $errmsg, $output) = run command => [ qw/emerge --info/ ],
                                        verbose => 0;
  if ($success) {
   for (@{$output || []}) {
    if (/^PORTDIR_OVERLAY=(.*)$/m) {
     $overlays = [ map abs_path($_), split ' ', _unquote($1) ];
    }
    if (/^ACCEPT_KEYWORDS=(.*)$/m) {
     $default_keywords = [ split ' ', _unquote($1) ];
    }
    if (/^DISTDIR=(.*)$/m) {
     $default_distdir = abs_path(_unquote($1));
    }
    if (/^PORTDIR=(.*)$/m) {
     $main_portdir = abs_path(_unquote($1));
    }
   }
  } else {
   error $errmsg;
  }
 }

 $default_keywords = [ 'x86' ] unless defined $default_keywords;
 $default_distdir  = '/usr/portage/distfiles' unless defined $default_distdir;

 return 1;
}

sub init {
 my ($self) = @_;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 $stat->mk_accessors(qw/name version author distribution desc uri src license
                        deps eb_name eb_version eb_dir eb_file fetched_arch
                        portdir_overlay
                        overlay distdir keywords do_manifest header footer
                        force verbose/);

 $stat->force($conf->get_conf('force'));
 $stat->verbose($conf->get_conf('verbose'));

 return 1;
}

our %gentooism = (
 'ANSIColor'               => 'Term-ANSIColor',
 'Audio-CD'                => 'Audio-CD-disc-cover',
 'CGI-Simple'              => 'Cgi-Simple',
 'Cache-Mmap'              => 'cache-mmap',
 'Class-Loader'            => 'class-loader',
 'Class-ReturnValue'       => 'class-returnvalue',
 'Config-General'          => 'config-general',
 'Convert-ASCII-Armour'    => 'convert-ascii-armour',
 'Convert-PEM'             => 'convert-pem',
 'Crypt-CBC'               => 'crypt-cbc',
 'Crypt-DES_EDE3'          => 'crypt-des-ede3',
 'Crypt-DH'                => 'crypt-dh',
 'Crypt-DSA'               => 'crypt-dsa',
 'Crypt-IDEA'              => 'crypt-idea',
 'Crypt-Primes'            => 'crypt-primes',
 'Crypt-RSA'               => 'crypt-rsa',
 'Crypt-Random'            => 'crypt-random',
 'DBIx-SearchBuilder'      => 'dbix-searchbuilder',
 'Data-Buffer'             => 'data-buffer',
 'Digest'                  => 'digest-base',
 'Digest-BubbleBabble'     => 'digest-bubblebabble',
 'Digest-MD2'              => 'digest-md2',
 'ExtUtils-Depends'        => 'extutils-depends',
 'ExtUtils-PkgConfig'      => 'extutils-pkgconfig',
 'Frontier-RPC'            => 'frontier-rpc',
 'Gimp'                    => 'gimp-perl',
 'Glib'                    => 'glib-perl',
 'Gnome2-Canvas'           => 'gnome2-canvas',
 'Gnome2-GConf'            => 'gnome2-gconf',
 'Gnome2-Print'            => 'gnome2-print',
 'Gnome2-VFS'              => 'gnome2-vfs-perl',
 'Gnome2-Wnck'             => 'gnome2-wnck',
 'Gtk2'                    => 'gtk2-perl',
 'Gtk2-Ex-FormFactory'     => 'gtk2-ex-formfactory',
 'Gtk2-GladeXML'           => 'gtk2-gladexml',
 'Gtk2-Spell'              => 'gtk2-spell',
 'Gtk2-TrayIcon'           => 'gtk2-trayicon',
 'Gtk2-TrayManager'        => 'gtk2-traymanager',
 'Gtk2Fu'                  => 'gtk2-fu',
 'I18N-LangTags'           => 'i18n-langtags',
 'Image-Info'              => 'ImageInfo',
 'Image-Size'              => 'ImageSize',
 'Inline-Files'            => 'inline-files',
 'Locale-Maketext'         => 'locale-maketext',
 'Locale-Maketext-Fuzzy'   => 'locale-maketext-fuzzy',
 'Locale-Maketext-Lexicon' => 'locale-maketext-lexicon',
 'Log-Dispatch'            => 'log-dispatch',
 'Math-Pari'               => 'math-pari',
 'Module-Info'             => 'module-info',
 'Net-Ping'                => 'net-ping',
 'Net-SFTP'                => 'net-sftp',
 'Net-SSH-Perl'            => 'net-ssh-perl',
 'Net-Server'              => 'net-server',
 'OLE-Storage_Lite'        => 'OLE-StorageLite',
 'Ogg-Vorbis-Header'       => 'ogg-vorbis-header',
 'PathTools'               => 'File-Spec',
 'Pod-Parser'              => 'PodParser',
 'Regexp-Common'           => 'regexp-common',
 'SDL_Perl'                => 'sdl-perl',
 'Set-Scalar'              => 'set-scalar',
 'String-CRC32'            => 'string-crc32',
 'Text-Autoformat'         => 'text-autoformat',
 'Text-Reform'             => 'text-reform',
 'Text-Template'           => 'text-template',
 'Text-Wrapper'            => 'text-wrapper',
 'Tie-EncryptedHash'       => 'tie-encryptedhash',
 'Tk'                      => 'perl-tk',
 'Wx'                      => 'wxperl',
 'YAML'                    => 'yaml',
 'gettext'                 => 'Locale-gettext',
 'txt2html'                => 'TextToHTML',
);

sub prepare {
 my $self = shift;
 my $mod  = $self->parent;
 my $stat = $self->status;
 my $int  = $mod->parent;
 my $conf = $int->configure_object;

 my %opts = @_;

 $stat->prepared(0);

 my $keywords = delete $opts{'keywords'};
 if (defined $keywords) {
  $keywords = [ split ' ', $keywords ];
 } else {
  $keywords = $default_keywords;
 }
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

 my $overlay = delete $opts{'overlay'};
 $overlay = (defined $overlay) ? abs_path $overlay : '/usr/local/portage';
 $stat->overlay($overlay);

 my $distdir = delete $opts{'distdir'};
 $distdir = (defined $distdir) ? abs_path $distdir : $default_distdir;
 $stat->distdir($distdir);

 if ($stat->do_manifest && !-w $stat->distdir) {
  error 'distdir isn\'t writable -- aborting';
  return 0;
 }
 $stat->fetched_arch($mod->status->fetch);

 my $cur = File::Spec::Functions::curdir();
 my $portdir_overlay;
 for (@$overlays) {
  if ($_ eq $overlay or File::Spec::Functions::abs2rel($overlay, $_) eq $cur) {
   $portdir_overlay = [ @$overlays ];
   last;
  }
 }
 $portdir_overlay = [ @$overlays, $overlay ] unless $portdir_overlay;
 $stat->portdir_overlay($portdir_overlay);

 my $name = $mod->package_name;
 $stat->name($name);

 my $version = $mod->package_version;
 $stat->version($version);

 my $author = $mod->author->cpanid;
 $stat->author($author);

 $stat->distribution($name . '-' . $version);

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
 $stat->eb_file($file);

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
   msg 'Ebuild already generated for ' . $stat->distribution . ' -- skipping';
  }
  if ($skip) {
   $stat->prepared(1);
   $stat->created(1);
   $stat->dist($file);
   return 1;
  }
 }

 $self->SUPER::prepare(%opts);

 $stat->prepared(0);

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
   push @depends, [ $obj->package_name, $version ];
  }
 }
 $stat->deps(\@depends);

 $stat->prepared(1);
 return 1;
}

sub create {
 my $self = shift;
 my $stat = $self->status;

 unless ($stat->prepared) {
  error 'Can\'t create ' . $stat->distribution . ' since it was never prepared -- aborting';
  $stat->created(0);
  $stat->dist(undef);
  return 0;
 }

 if ($stat->created) {
  msg $stat->distribution . ' was already created -- skipping';
  $stat->dist($stat->eb_file);
  return 1;
 }

 $stat->created(0);
 $stat->dist(undef);

 $self->SUPER::create(@_);

 $stat->created(0);
 $stat->dist(undef);

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
 $d   .= 'S="${WORKDIR}/' . $stat->distribution . "\"\n";
 $d   .= 'DESCRIPTION="' . $stat->desc . "\"\n";
 $d   .= 'HOMEPAGE="' . $stat->uri . "\"\n";
 $d   .= 'SRC_URI="' . $stat->src . "\"\n";
 $d   .= "SLOT=\"0\"\n";
 $d   .= 'LICENSE="|| ( ' . join(' ', sort @{$stat->license}) . " )\"\n";
 $d   .= 'KEYWORDS="' . join(' ', sort @{$stat->keywords}) . "\"\n";
 $d   .= 'DEPEND="' . join("\n",
  'dev-lang/perl',
  map $self->_cpan2portage(@$_), @{$stat->deps}
 ) . "\"\n";
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

  msg 'Adding Manifest entry for ' . $stat->distribution;
  unless ($self->_run([ 'ebuild', $file, 'manifest' ], 0)) {
   1 while unlink $file;
   return 0;
  }
 }

 $stat->created(1);
 $stat->dist($file);
 return 1;
}

sub _cpan2portage {
 my ($self, $name, $version) = @_;

 $name = $gentooism{$name} || $name;
 my $ver;
 $ver = eval { version->new($version) } if defined $version;

 my @portdirs = ($main_portdir, @{$self->status->portdir_overlay});

 for my $category (qw/virtual perl-core dev-perl perl-gcpan/, CATEGORY) {
  my $atom = ($category eq 'virtual' ? 'perl-' : '') . $name;

  for my $portdir (@portdirs) {
   my @ebuilds = glob catfile($portdir, $category, $atom,"$atom-*.ebuild");
   next unless @ebuilds;

   if (defined $ver) { # implies that $version is defined
    for (@ebuilds) {
     next unless /\Q$atom\E-v?([\d._]+).*?\.ebuild$/;
     my $eb_ver = eval { version->new($1) };
     next unless defined $eb_ver and $eb_ver >= $ver;
     return ">=$category/$atom-$version";
    }
   } else {
    return "$category/$atom";
   }

  }

 }

 error "Couldn't find an appropriate ebuild for $name in the portage tree -- skipping";
 return '';
}

sub install {
 my $self = shift;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 my $sudo = $conf->get_program('sudo');
 my @cmd = ('emerge', '=' . $stat->eb_name . '-' . $stat->eb_version);
 unshift @cmd, $sudo if $sudo;

 my $success = $self->_run(\@cmd, 1);
 $stat->installed($success);

 return $success;
}

sub uninstall {
 my $self = shift;
 my $stat = $self->status;
 my $conf = $self->parent->parent->configure_object;

 my $sudo = $conf->get_program('sudo');
 my @cmd = ('emerge', '-C', '=' . $stat->eb_name . '-' . $stat->eb_version);
 unshift @cmd, $sudo if $sudo;

 my $success = $self->_run(\@cmd, 1);
 $stat->uninstalled($success);

 return $success;
}

sub _run {
 my ($self, $cmd, $verbose) = @_;
 my $stat = $self->status;

 my ($success, $errmsg, $output) = do {
  local $ENV{PORTDIR_OVERLAY}     = join ' ', @{$stat->portdir_overlay};
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

L<CPANPLUS>, L<IPC::Cmd> (core modules since 5.9.5), L<version> (since 5.009).

L<Cwd> (since perl 5) L<File::Path> (5.001), L<File::Copy> (5.002), L<File::Spec::Functions> (5.00504).

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

Copyright 2008-2009 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo
