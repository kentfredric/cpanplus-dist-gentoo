package CPANPLUS::Dist::Gentoo::Maps;

use strict;
use warnings;

=head1 NAME

CPANPLUS::Dist::Gentoo::Maps - Map CPAN objects to Gentoo and vice versa.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 DESCRPITON

This is an helper package to L<CPANPLUS::Dist::Gentoo>.

=cut

our %gentooisms;

/^\s*([\w-]+)\s+([\w-]+)\s*$/ and $gentooisms{$1} = $2 while <DATA>;

close DATA;

=head1 FUNCTIONS

=head2 C<name_c2g $name>

Maps a CPAN distribution name to its Gentoo counterpart.

=cut

sub name_c2g {
 my ($name) = @_;
 return $gentooisms{$name} || $name;
}

=head2 C<version_c2g $version>

Converts a CPAN version to a Gentoo version.

=cut

sub version_c2g {
 my ($v) = @_;

 $v =~ y/-/_/;
 $v =~ y/0-9._//cd;

 $v =~ s/^[._]*//;
 $v =~ s/[._]*$//;
 $v =~ s/([._])[._]*/$1/g;

 ($v, my $patch, my @rest) = split /_/, $v;
 $v .= '_p' . $patch if defined $patch;
 $v .= join('.', '', @rest) if @rest;

 return $v;
}

=head2 C<version_gcmp $va, $vb>

Compares two Gentoo versions.

=cut

sub version_gcmp {
 my ($a, $b) = map { defined() ? $_ : 0 } @_;

 for ($a, $b) {
  s/^[._]+//g;
  s/[._]+$//g;
  if (/^([\d.]*\d)\.*(?:_p\.*(\d[\d.]*))?\.*(?:-r(\d+))?$/) {
   $_ = {
    v => [ split /\.+/, $1 ],
    p => [ split /\.+/, $2 || 0 ],
    r => [ $3 || 0 ],
   };
  } else {
   require Carp;
   Carp::croak("Couldn't parse version string '$_'");
  }
 }

 for my $k (qw/v p r/) {
  my $xa = $a->{$k};
  my $xb = $b->{$k};
  while (@$xa or @$xb) {
   my $na = shift(@$xa) || 0;
   my $nb = shift(@$xb) || 0;
   my $c  = $na <=> $nb;
   return $c if $c;
  }
 }

 return 0;
}

=head1 SEE ALSO

L<CPANPLUS::Dist::Gentoo>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-gentoo at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-Gentoo>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::Gentoo

=head1 COPYRIGHT & LICENSE

Copyright 2009 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of CPANPLUS::Dist::Gentoo::Maps

__DATA__
ANSIColor               Term-ANSIColor
Audio-CD                Audio-CD-disc-cover
CGI-Simple              Cgi-Simple
Cache-Mmap              cache-mmap
Class-Loader            class-loader
Class-ReturnValue       class-returnvalue
Config-General          config-general
Convert-ASCII-Armour    convert-ascii-armour
Convert-PEM             convert-pem
Crypt-CBC               crypt-cbc
Crypt-DES_EDE3          crypt-des-ede3
Crypt-DH                crypt-dh
Crypt-DSA               crypt-dsa
Crypt-IDEA              crypt-idea
Crypt-Primes            crypt-primes
Crypt-RSA               crypt-rsa
Crypt-Random            crypt-random
DBIx-SearchBuilder      dbix-searchbuilder
Data-Buffer             data-buffer
Digest                  digest-base
Digest-BubbleBabble     digest-bubblebabble
Digest-MD2              digest-md2
ExtUtils-Depends        extutils-depends
ExtUtils-PkgConfig      extutils-pkgconfig
Frontier-RPC            frontier-rpc
Gimp                    gimp-perl
Glib                    glib-perl
Gnome2-Canvas           gnome2-canvas
Gnome2-GConf            gnome2-gconf
Gnome2-Print            gnome2-print
Gnome2-VFS              gnome2-vfs-perl
Gnome2-Wnck             gnome2-wnck
Gtk2                    gtk2-perl
Gtk2-Ex-FormFactory     gtk2-ex-formfactory
Gtk2-GladeXML           gtk2-gladexml
Gtk2-Spell              gtk2-spell
Gtk2-TrayIcon           gtk2-trayicon
Gtk2-TrayManager        gtk2-traymanager
Gtk2Fu                  gtk2-fu
I18N-LangTags           i18n-langtags
Image-Info              ImageInfo
Image-Size              ImageSize
Inline-Files            inline-files
Locale-Maketext         locale-maketext
Locale-Maketext-Fuzzy   locale-maketext-fuzzy
Locale-Maketext-Lexicon locale-maketext-lexicon
Log-Dispatch            log-dispatch
Math-Pari               math-pari
Module-Info             module-info
Net-Ping                net-ping
Net-SFTP                net-sftp
Net-SSH-Perl            net-ssh-perl
Net-Server              net-server
OLE-Storage_Lite        OLE-StorageLite
Ogg-Vorbis-Header       ogg-vorbis-header
PathTools               File-Spec
Pod-Parser              PodParser
Regexp-Common           regexp-common
SDL_Perl                sdl-perl
Set-Scalar              set-scalar
String-CRC32            string-crc32
Text-Autoformat         text-autoformat
Text-Reform             text-reform
Text-Template           text-template
Text-Wrapper            text-wrapper
Tie-EncryptedHash       tie-encryptedhash
Tk                      perl-tk
Wx                      wxperl
YAML                    yaml
gettext                 Locale-gettext
txt2html                TextToHTML
