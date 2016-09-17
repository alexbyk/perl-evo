package Evo::Export::Meta;
use Evo 'Evo::Internal::Util; Carp croak; Module::Load load';

our @CARP_NOT = qw(Evo Evo::Export Evo::Internal::Util);

sub package($self) { $self->{package} }
sub symbols($self) { $self->{symbols} //= {} }

# build once per package or die
sub bind_to ($me, $pkg, %opts) {
  croak "$pkg already has $me instance" if Evo::Internal::Util::pkg_stash($pkg, $me);
  my $obj = $me->new($pkg, %opts);
  Evo::Internal::Util::pkg_stash($pkg, $me, $obj);
}

sub new ($me, $pkg, %opts) {
  $me = ref($me) if ref $me;
  bless {%opts, package => $pkg}, $me;
}

sub find_or_bind_to ($class, $package, %opts) {
  my $obj = Evo::Internal::Util::pkg_stash($package, $class);
  $obj = $class->bind_to($package, %opts) if !$obj;
  $obj;
}

# it's important to return same function for the same module
sub request ($self, $name, $dpkg) {
  my $slot = $self->find_slot($name);
  my $fn;
  my $type = $slot->{type};
  if ($type eq 'code') {
    $fn = $slot->{code};
  }
  elsif ($type eq 'gen') {
    return $slot->{cache}{$dpkg} if $slot->{cache}{$dpkg};
    return $slot->{cache}{$dpkg} = $slot->{gen}->($self->package, $dpkg);
  }

  croak "Something wrong" unless $fn;
  return $fn;
}

# traverse to find gen via links, return Module, name, gen
sub find_slot ($self, $name) {
  croak qq{"${\$self->package}" doesn't export "$name"} unless my $slot = $self->symbols->{$name};
}

sub init_slot ($self, $name, $val) {
  my $pkg = $self->package;
  croak "$pkg already exports $name" if $self->symbols->{$name};
  $self->symbols->{$name} = $val;
}

sub export_from ($self, $name, $origpkg, $origname) {
  my $slot = $self->find_or_bind_to($origpkg)->find_slot($origname);
  $self->init_slot($name, $slot);
}

sub export_gen ($self, $name, $gen) {
  $self->init_slot($name, {gen => $gen, type => 'gen'});
}

sub export_code ($self, $name, $sub) {
  $self->init_slot($name, {type => 'code', code => $sub});
}

sub export ($self, $name_as) {
  my $pkg = $self->package;
  my ($name, $as) = split ':', $name_as;
  $as ||= $name;
  my $full = "${pkg}::$name";
  no strict 'refs';    ## no critic
  my $sub = *{$full}{CODE} or croak "Subroutine $full doesn't exists";
  $self->export_code($as, $sub);
}


sub export_proxy ($self, $origpkg, @xlist) {
  $origpkg = Evo::Internal::Util::resolve_package($self->package, $origpkg);
  load $origpkg;
  my @list = $self->find_or_bind_to($origpkg)->expand_wildcards(@xlist);

  foreach my $name_as (@list) {
    my ($origname, $name) = split ':', $name_as;
    $name ||= $origname;
    $self->export_from($name, $origpkg, $origname);
  }
}


sub expand_wildcards ($self, @list) {
  my %symbols = $self->symbols->%*;
  my (%minus, %res);
  foreach my $cur (@list) {
    if ($cur eq '*') {
      croak "${\$self->package} exports nothing" unless %symbols;
      $res{$_}++ for keys %symbols;
    }
    elsif ($cur =~ /^-(.+)/) {
      $minus{$1}++;
    }
    else {
      $res{$cur}++;
    }
  }
  return (sort grep { !$minus{$_} } keys %res);
}

sub install ($self, $dst, @xlist) {
  my @list = $self->expand_wildcards(@xlist);

  my $liststr = join '; ', @list;
  my $exporter = $self->package;
  Evo::Internal::Util::debug("Installing $exporter [$liststr] to $dst");

  my %patch;
  foreach my $name_as (@list) {
    my ($name, $as) = split ':', $name_as;
    $as ||= $name;
    my $fn = $self->request($name, $dst);
    $patch{$as} = $fn;
  }
  Evo::Internal::Util::monkey_patch $dst, %patch;
}

no warnings 'once';
*info = *symbols;

1;
