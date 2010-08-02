package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use Config;

sub build_binaries {
  my ($self, $build_out, $srcdir) = @_;
  my $prefixdir = rel2abs($build_out);
  my $perl = $^X;
  
  die "###ERROR### Build for MS Windows not implemented yet"; # xxx kmx todo
  
  # for GNU make on MS Windows it is safer to convert \ to /
  $perl =~ s|\\|/|g;
  $prefixdir =~ s|\\|/|g;

  my $make = $self->get_make;
  print "Gonna call make install ...\n";
  my @cmd;
  if($make =~ /nmake/ && $Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    my $makefile = rel2abs('patches\Makefile.nmake');
    if ($Config{archname} =~ /x64/) { #64bit
      @cmd = ( $make, '-f', $makefile, "PERL=perl", "PREFIX=$prefixdir", "CFG=Win64", "install" );
    }
    else { #32bit
      @cmd = ( $make, '-f', $makefile, "PERL=perl", "PREFIX=$prefixdir", "install" );
    }    
  }
  else { # gcc compiler
    my $makefile = rel2abs('patches\Makefile.mingw');
    @cmd = ( $make, '-f', $makefile, "PERL=$perl", "PREFIX=$prefixdir", "CC=$Config{cc}", "install" );
  }
  print "[cmd: ".join(' ',@cmd)."]\n";
  chdir $srcdir;
  $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";
  chdir $self->base_dir();

  return 1;
}

sub get_make {
  my ($self) = @_;
  my @try = ( 'dmake', 'mingw32-make', 'gmake', 'make', $Config{make}, $Config{gmake} );
  print "Gonna detect make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    print "- testing: '$name'\n";
    if (system("$name --help 2>nul 1>nul") != 256) {
      # I am not sure if this is the right way to detect non existing executable
      # but it seems to work on MS Windows (more or less)
      print "- found: '$name'\n";
      return $name;
    };
  }
  print "- fallback to: 'dmake'\n";
  return 'dmake';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|"|\\"|g;
    return qq("$txt");
}

1;
