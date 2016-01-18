package Evo::Lib::Bare;
use strict;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use Carp qw(carp croak);


my $NAME = do {
  local $@;
  eval { require Sub::Util; Sub::Util->can('set_subname') } || sub { $_[1] };
};

use constant SUBRE => qr/^[a-zA-Z_]\w*$/;
sub check_subname { $_[0] =~ SUBRE }

my $DEBUG = $ENV{EVO_DEBUG};
sub debug { return unless $DEBUG; carp "[${\(caller)[0]}]: $_[0]"; }


# usefull?
sub find_caller_except($skip_ns, $i, $caller) {
  while ($caller = (caller($i++))[0]) {
    return $caller if $caller ne $skip_ns;
  }
}

sub monkey_patch($pkg, %hash) {
  no strict 'refs';    ## no critic
  *{"${pkg}::$_"} = $NAME->("${pkg}::$_", $hash{$_}) for keys %hash;
}

#todo: decide what to do with empty subroutins
sub monkey_patch_silent($pkg, %hash) {
  no strict 'refs';    ## no critic
  no warnings 'redefine';
  my %restore;
  foreach my $name (keys %hash) {
    $restore{$name} = *{"${pkg}::$name"}{CODE};
    warn "Can't delete empty ${pkg}::$name" and next unless $hash{$name};
    *{"${pkg}::$name"} = $NAME->("${pkg}::$name", $hash{$name});
  }
  \%restore;
}


sub list_symbols($pkg) {
  no strict 'refs';    ##no critic
  grep { $_ =~ /^[a-zA-Z_]\w*$/ } keys %{"${pkg}::"};
}

sub undef_symbols($ns) {
  no strict 'refs';    ## no critic
  undef *{"${ns}::$_"} for list_symbols($ns);
}


sub uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

# returns a subroutine than can pretend a code in the other package/file/line
sub inject(%opts) {
  my ($package, $filename, $line, $code) = @opts{qw(package filename line code)};

  ## no critic
  (
    eval qq{package $package;
#line $line "$filename"
    sub { \$code->(\@_) }}
  );
}

sub find_subnames($pkg, $code) {
  no strict 'refs';    ## no critic
  my %symbols = %{$pkg . "::"};

  # because use constant adds refs to package symbols hash
  grep { !ref($symbols{$_}) && (*{$symbols{$_}}{CODE} // 0) == $code } keys %symbols;
}


our $RX_PKG_NOT_FIRST = qr/[0-9A-Z_a-z]+(?:::[0-9A-Z_a-z]+)*/;
our $RX_PKG           = qr/^[A-Z_a-z]$RX_PKG_NOT_FIRST*$/;

sub _parent($caller, $rel) {
  my @arr = split /::/, $caller;
  pop @arr;
  push @arr, $rel if $rel;
  join '::', @arr;
}

sub resolve_package($caller, $pkg) {
  return $pkg if $pkg =~ $RX_PKG;

  if ($pkg =~ /^\-($RX_PKG_NOT_FIRST)$/) {
    return "Evo::$1";
  }
  elsif ($pkg =~ /^:($RX_PKG_NOT_FIRST)$/) {
    return "${caller}::$1";
  }
  elsif ($pkg =~ /^::($RX_PKG_NOT_FIRST*)$/) {
    my $resolved = _parent($caller, $1);
    return $resolved if $resolved =~ /^$RX_PKG$/;
  }

  croak "Can't resolve $pkg for caller $caller";
}

1;

=head1 DESCRIPTION

This is bare internal collection, this functions are used by Exporter, so we need this module and can't export them

=cut
