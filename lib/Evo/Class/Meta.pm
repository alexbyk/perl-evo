package Evo::Class::Meta;
use Evo
  'Carp croak; -Lib monkey_patch monkey_patch_silent code2names names2code; -Lib::Bare; -Export *';
use Evo '/::Util compile_attr parse_style';

our @CARP_NOT
  = qw(Evo::Class::Gen::Array Evo::Class::Gen::Hash Evo::Class::Gen::HUF Evo::Class::Common);

sub class($self) { $self->{class} || die "no class" }
sub gen($self)   { $self->{gen}   || die "no gen" }
sub builder_options ($self) { $self->{_bo} ||= {}; }

sub cached_init {
  return $_[0]->{cached_init} if @_ == 1;
  $_[0]->{cached_init} = $_[1];
  $_[0];
}

sub new ($class, %opts) {
  croak "provide class" unless $opts{class};
  bless {overriden => {}, requirements => {}, methods => {}, private => {}, attrs => {}, %opts},
    $class;
}

sub _once ($self, $name, $key, $val) {

  # for case whan "has_overrined" follows "extends"
  croak "${\$self->class} already has \"$name\""
    if $self->is_public($name) && !$self->is_overriden($name);
  Evo::Lib::Bare::check_subname($name) || croak(qq{"$name" is invalid name});
  $self->{$key}{$name} = $val;
}


sub _is_own ($class, $name, $code) {
  my ($pkg, $realname) = code2names($code);
  return $pkg eq $class && $realname eq $name;
}

# !!!is_public isn't an opposite to is_private
sub is_public ($self, $name) {
  $self->is_public_attr($name) || $self->is_public_method($name);
}

sub is_public_attr ($self, $name) {
  return   if $self->is_private($name);
  return 1 if $self->{attrs}{$name};
  return;
}

sub is_public_method ($self, $name) {
  return   if $self->is_private($name);
  return 1 if exists $self->{methods}{$name};
  my $class = $self->class;
  my $code = names2code($class, $name) or return;
  return _is_own($class, $name, $code);
}

sub mark_private ($self, $name) {
  $self->{private}{$name}++;
}

sub is_private ($self, $name) {
  $self->{private}{$name};
}

sub public_attrs($self) {
  map { ($_, $self->{attrs}{$_}) }
    grep { $self->is_public_attr($_) } Evo::Lib::Bare::list_symbols($self->class);
}

sub public_methods($self) {
  my $class = $self->class;
  map { ($_, names2code($class, $_)) }
    grep { $self->is_public_method($_) } Evo::Lib::Bare::list_symbols($self->class);
}

sub requirements($self) {
  my %all = ($self->public_attrs, $self->public_methods, $self->{requirements}->%*);
  keys %all;
}

sub reg_requirement ($self, $name) {
  $self->{requirements}{$name}++;
}


# means register external sub as method. Because every sub in the current package
# is public by default
sub reg_method ($self, $name) {
  my $class = $self->class;

  # check if exists
  my $code = names2code($class, $name) or croak "$class::$name doesn't exist";

  $self->_once($name, 'methods', 'public');
}


sub reg_attr ($self, $name, %opts) {
  $self->cached_init(undef)->_once($name, attrs => \%opts);
}

sub _map ($self, $what) {
  map { $_ => $self->{public}{$_}{value} }
    grep { $self->{public}{$_}{type} eq $what } keys $self->{public}->%*;
}


# it's important that $self->{builder_options} never changes and is updated by ref
sub update_builder_options ($self) {

  my $bo = $self->builder_options;
  %{$bo} = (known => {}, required => [], dv => {}, dfn => {}, check => {});
  my %attrs = $self->{attrs}->%*;    # not public, all
  for my $name (keys %attrs) {
    my %o = $attrs{$name}->%*;
    $bo->{known}{$name}++;
    push $bo->{required}->@*, $name if $o{required};
    (ref $o{default} ? $bo->{dfn} : $bo->{dv})->{$name} = $o{default} if exists $o{default};
    $bo->{check}{$name} = $o{check} if $o{check};
  }
}

sub compile_builder ($self) {
  my $init;
  return $init if $init = $self->cached_init;
  $self->update_builder_options;
  $self->cached_init($init = $self->gen->{init}->($self->class, $self->builder_options));
  $init;
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

  my %attrs   = $other->public_attrs();
  my %methods = $other->public_methods();
  my @names   = (keys(%attrs), keys(%methods));

  foreach my $name (keys %attrs) {
    next if $self->is_overriden($name);
    croak qq{Class $class already can "$name", can't install attr} if $class->can($name);
    $self->install_attr($name, $attrs{$name}->%*);
  }


  foreach my $name (keys %methods) {
    next if $self->is_overriden($name);
    croak qq{Class $class already can "$name", can't install method} if $class->can($name);
    monkey_patch $class, $name, names2code($other->class, $name);
    $self->reg_method($name);
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
