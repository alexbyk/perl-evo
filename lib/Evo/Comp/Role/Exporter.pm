package Evo::Comp::Role::Exporter;
use Evo;
use Evo::Util;
use Carp 'croak';
use Module::Load;


sub data { shift->{data} }
sub new { bless {data => {}}, __PACKAGE__ }

sub init_slot($self, $src, $name, $val) {
  croak "$src already adds $name" if $self->data->{$src}{export}{$name};
  $self->data->{$src}{export}{$name} = $val;
}

sub add_methods($self, $role, @methods) {
  no strict 'refs';    ## no critic
  foreach my $m (@methods) {
    my $full = "${role}::$m";
    my $sub = *{$full}{CODE} or croak "Method $full doesn't exists";
    $self->init_slot($role, $m, {type => 'method', value => $sub});
  }
}

sub add_gen($self, $role, $name, $gen) {
  $self->init_slot($role, $name, {type => 'gen', value => $gen});
}

sub request_gen($self, $role, $name, $comp) {
  my $slot = $self->data->{$role}{export}{$name}
    or croak qq#"$role" doesn't provide method "$name"#;

  # it's important to return same function for the same module
  return $slot->{cache}{$comp} if $slot->{cache}{$comp};
  return $slot->{cache}{$comp} = $slot->{value}->($comp);
}

sub add_attr($self, $role, $name, @opts) {
  Evo::Util::check_subname($name) || croak(qq{Attribute "$name" invalid});
  $self->init_slot($role, $name, {type => 'attr', value => \@opts});
}

sub _map($self, $type, $role) {
  my $all = $self->data->{$role}{export};
  map { ($_, $all->{$_}->{value}) } grep { $all->{$_}->{type} eq $type } keys %$all;
}

sub methods($self, $role, $comp) {
  my %gens = $self->_map('gen', $role);
  my %gms = map { $_ => $gens{$_}->($comp) } keys %gens;
  (%gms, $self->_map('method', $role),);
}

sub attrs($self, $role) { $self->_map('attr', $role); }

sub hooks($self, $role, @hooks) {

  return $self->data->{$role}
    && $self->data->{$role}{hooks} ? ($self->data->{$role}{hooks}->@*) : ()
    if !@hooks;
  push @{($self->data->{$role}{hooks} ||= [])}, @hooks;
}

sub proxy($self, $dst, $src) {
  load $src;

  my $data_src = $self->data->{$src} || {};
  my $add_src  = $data_src->{export} || {};
  my $data_dst = $self->data->{$dst} ||= {};
  my $add_dst  = $data_dst->{export} ||= {};


  exists $add_dst->{$_} and croak qq#"$_" in "$src" clashes with "$dst"# for keys %$add_src;

  $add_dst->{$_} = $add_src->{$_} for keys %$add_src;

  my @hooks = $self->hooks($src);
  $self->hooks($dst, @hooks) if @hooks;
}

1;
