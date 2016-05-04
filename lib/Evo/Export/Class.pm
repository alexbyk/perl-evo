package Evo::Export::Class;
use strict;
use warnings;
use feature 'signatures';
no warnings "experimental::signatures";
use Evo::Lib::Bare;
use Carp 'croak';
use Module::Load 'load';

our @CARP_NOT = qw(Evo Evo::Lib::Bare);
sub new { bless {data => {}}, __PACKAGE__ }
use constant DEFAULT => new();

sub data { shift->{data} }

sub install ($self, $src, $dst, @xlist) {
  my @list = $self->expand_wildcards($src, @xlist);

  my %patch;
  foreach my $name_as (@list) {
    my ($name, $as) = split ':', $name_as;
    $as ||= $name;
    my $fn = $self->request_gen($src, $name, $dst);
    $patch{$as} = $fn;
  }

  Evo::Lib::Bare::monkey_patch $dst, %patch;
}

sub request_gen ($self, $epkg, $name, $dpkg) {
  my $slot = $self->find_slot($epkg, $name);

  # it's important to return same function for the same module
  return $slot->{cache}{$dpkg} if $slot->{cache}{$dpkg};
  return $slot->{cache}{$dpkg} = $slot->{gen}->($dpkg);
}

# traverse to find gen via links, return Module, name, gen
sub find_slot ($self, $pkg, $name) {
  croak qq{"$pkg" doesn't export "$name"} unless my $slot = $self->data->{$pkg}{$name};
}

sub init_slot ($self, $src, $name, $val) {
  croak "$src already exports $name" if $self->data->{$src}{$name};
  $self->data->{$src}{$name} = $val;
}

sub add_proxy ($self, $epkg, $ename, $spkg, $sname) {
  my $slot = $self->find_slot($spkg, $sname);
  $self->init_slot($epkg, $ename, $slot);
}

sub add_gen ($self, $src, $name, $gen) {
  $self->init_slot($src, $name, {gen => $gen});
}

sub add_sub ($self, $src, $name_as) {
  my ($name, $as) = split ':', $name_as;
  $as ||= $name;
  my $full = "${src}::$name";
  no strict 'refs';    ## no critic
  my $sub = *{$full}{CODE} or croak "Subroutine $full doesn't exists";
  $self->add_gen($src, $as, sub {$sub});
}

sub proxy ($self, $epkg, $spkg, @xlist) {
  $spkg = Evo::Lib::Bare::resolve_package($epkg, $spkg);
  load $spkg;
  my @list = $self->expand_wildcards($spkg, @xlist);

  foreach my $name_as (@list) {
    my ($sname, $ename) = split ':', $name_as;
    $ename ||= $sname;
    $self->add_proxy($epkg, $ename, $spkg, $sname);
  }

}

sub expand_wildcards ($self, $src, @list) {
  croak "Empty list" unless @list;

  my $data = $self->data->{$src};
  my (%minus, %res);
  foreach my $cur (@list) {
    if ($cur eq '*') {
      croak "$src exports nothing, can't expand *" unless $data;
      $res{$_}++ for keys %$data;
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


1;
