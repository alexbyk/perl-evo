package Evo::Class::Meta;
use Evo
  'Carp croak; -Lib monkey_patch monkey_patch_silent; -Lib::Bare; -Export *';
use Evo '/::Util compile_attr parse_style';

our @CARP_NOT
  = qw(Evo::Class::Gen::Array Evo::Class::Gen::Hash Evo::Class::Gen::HUF Evo::Class::Common);

sub class($self) { $self->{class} || die "no class" }
sub gen($self)   { $self->{gen}   || die "no gen" }
sub builder_options ($self) { $self->{_bo} ||= {}; }

sub new (%opts) {
  croak "provide class" unless $opts{class};
  bless {overriden => {}, data => {}, %opts}, __PACKAGE__;
}

sub _once ($self, $name, %opts) {

  # for case whan "has_overrined" follows "extends"
  croak "${\$self->class} already has $name"
    if $self->{data}{$name} && !$self->is_overriden($name);
  Evo::Lib::Bare::check_subname($name) || croak(qq{"$name" is invalid name});
  $self->{data}{$name} = \%opts;
}

sub reg_requirement ($self, $name) {
  $self->_once($name, type => 'requirement', value => 1);
}


sub reg_method ($self, $name, %opts) {
  $self->_once($name, type => 'method', value => \%opts);
}

sub reg_attr ($self, $name, %opts) {
  $self->_once($name, type => 'attr', value => \%opts);
}

sub _map ($self, $what) {
  map { $_ => $self->{data}{$_}{value} }
    grep { $self->{data}{$_}{type} eq $what } keys $self->{data}->%*;
}

sub attrs($self)   { $self->_map('attr') }
sub methods($self) { $self->_map('method') }

sub requirements($self) { keys $self->{data}->%*; }


# it's important that $self->{builder_options} never changes and is updated by ref
sub update_builder_options ($self) {

  my $bo = $self->builder_options;
  %{$bo} = (known => {}, required => [], dv => {}, dfn => {}, check => {});
  my %attrs = $self->attrs;
  for my $name (keys %attrs) {
    my %o = $attrs{$name}->%*;
    $bo->{known}{$name}++;
    push $bo->{required}->@*, $name if $o{required};
    (ref $o{default} ? $bo->{dfn} : $bo->{dv})->{$name} = $o{default} if exists $o{default};
    $bo->{check}{$name} = $o{check} if $o{check};
  }
}

sub compile_builder ($self) {
  $self->update_builder_options;
  return $self->{gen}{new}->($self->class, $self->builder_options);
}

sub install_attr ($self, $name, @o) {


  my %o = parse_style(@o);
  $self->reg_attr($name, %o);
  my $class = $self->class;

  my %ao = _process_is($name, %o);
  my $attr_fn = compile_attr($self->gen, $name, %ao);

  # for case whan "has_overrined" follows "extends"
  $self->is_overriden($name)
    ? monkey_patch_silent($class, $name => $attr_fn)
    : monkey_patch($class, $name => $attr_fn);
  $self->update_builder_options();
}

sub _process_is ($name, %res) {
  my $is = delete($res{is}) || 'rw';
  croak qq#invalid "is": "$is"# unless $is eq 'ro' || $is eq 'rw';

  $res{check} = sub { croak qq#Attribute "$name" is readonly#; }
    if $is eq 'ro';    # ro replaces check
  return %res;
}

sub mark_overriden ($self, $name) {
  $self->{overriden}{$name}++;
  $self;
}

sub is_overriden ($self, $name) {
  $self->{overriden}{$name};
}

sub extend_with ($self, $other) {
  my $class = $self->class;

  my %attrs   = $other->attrs();
  my %methods = $other->methods();
  my @names   = (keys(%attrs), keys(%methods));

  foreach my $name (keys %attrs) {
    next if $self->is_overriden($name);
    croak qq{Class $class already can "$name", can't install attr} if $class->can($name);
    $self->install_attr($name, $attrs{$name}->%*);
  }


  foreach my $name (keys %methods) {
    next if $self->is_overriden($name);
    croak qq{Class $class already can "$name", can't install method} if $class->can($name);
    $self->reg_method($name, $methods{$name}->%*);
    monkey_patch $class, $name, $methods{$name}{code};
  }

  $self;
}

sub check_implementation ($self, $inter) {
  my ($self_class, $inter_class) = ($self->class, $inter->class);
  my @reqs = sort $inter->requirements;
  croak qq{Empty class "$inter_class", nothing to check} unless @reqs;

  my @not_exists = grep { !$self_class->can($_); } @reqs;
  return $self if !@not_exists;

  croak qq/Bad implementation of "$inter_class", missing in "$self_class": /, join ';',
    @not_exists;
}

sub with ($self, $parent) {
  $self->extend_with($parent)->check_implementation($parent);
}

1;
