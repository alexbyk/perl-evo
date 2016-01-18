package Evo::Comp::Meta;
use Evo 'Carp croak; -Lib::Internal monkey_patch; Module::Load load; -Lib::Bare';


our @CARP_NOT = qw(Evo::Comp::Gen::Array Evo::Comp::Gen::Hash Evo::Comp::Gen::HUF);
my @KNOWN = qw(default required lazy check is);

# ---- methods ---
sub data { shift->{data} }

sub new { bless {data => {}, @_}, __PACKAGE__; }


sub builder_options($self, $class) { $self->data->{$class}{bo} ||= {}; }

# allow comp to override this methods
sub mark_overriden($self, $comp, @list) { $self->data->{$comp}{override}{$_}++ for @list }

sub install_attr($self, $class, $name, @xopts) {
  my $data = $self->data->{$class} ||= {};
  croak qq{"$class" already has attribute "$name"} if $data->{attrs}{$name};

  my %o = $self->parse_style(@xopts);
  $data->{attrs}{$name} = \%o;

  my %ao = process_is($name, %o);
  my $attr_fn = $self->compile_attr($name, %ao);
  monkey_patch $class, $name => $attr_fn;

  $self->update_builder_options($class);
}

# ro just adds chet wrapper
sub compile_attr($self, $name, %opts) {
  my $gen = $self->{gen} || croak "No gen";
  my $lt = exists $opts{lazy} && (ref $opts{lazy} ? 'CODE' : 'VALUE');
  my $ch = $opts{check};

  my $res;
  if (!$lt) {
    $res = $ch ? $gen->{gsch}->($name, $ch) : $gen->{gs}->($name);
  }
  elsif ($lt eq 'VALUE') {
    $res
      = $ch
      ? $gen->{gsch_value}->($name, $ch, $opts{lazy})
      : $gen->{gs_value}->($name, $opts{lazy});
  }
  elsif ($lt eq 'CODE') {
    $res
      = $ch ? $gen->{gsch_code}->($name, $ch, $opts{lazy}) : $gen->{gs_code}->($name, $opts{lazy});
  }
  else { croak "Bad type $lt"; }

  $res;
}

sub update_builder_options($self, $class) {
  my $bo = $self->builder_options($class);

  # !!!reset by ref
  %{$bo} = (known => {}, required => [], dv => {}, dfn => {}, check => {});
  my %attrs = ($self->data->{$class}{attrs} ||= {})->%*;
  for my $name (keys %attrs) {
    my %o = $attrs{$name}->%*;
    $bo->{known}{$name}++;
    push $bo->{required}->@*, $name if $o{required};
    (ref $o{default} ? $bo->{dfn} : $bo->{dv})->{$name} = $o{default} if exists $o{default};
    $bo->{check}{$name} = $o{check} if $o{check};
  }
}

sub compile_builder($self, $class) {
  $self->update_builder_options($class);
  return $self->{gen}{new}->($class, $self->builder_options($class));
}

sub parse_style($self, @attr) {
  my %unknown = my %opts = (@attr % 2 ? (default => @attr) : @attr);
  delete $unknown{$_} for @KNOWN;
  croak "unknown options: " . join(',', sort keys %unknown) if keys %unknown;
  croak "providing default and setting required doesn't make sense"
    if exists $opts{default} && $opts{required};

  _scalar_or_code(\%opts, 'lazy');
  _scalar_or_code(\%opts, 'default');

  %opts;
}

sub rex($self) { $self->{rex} }

sub install_roles($self, $comp, @roles) {
  my $rex = $self->{rex} or die "no rex";
  no strict 'refs';    ## no critic
  my @hslots;
  foreach my $role (map { Evo::Lib::Bare::resolve_package($comp, $_) } @roles) {
    load $role;

    my %attrs   = $rex->attrs($role);
    my %methods = $rex->methods($role, $comp);
    my @names   = (keys(%attrs), keys(%methods));
    croak qq{Empty role "$role". Not a Role?} unless @names;

    foreach my $name (keys %attrs) {
      next if $self->data->{$comp}{override}{$name};
      croak qq{Component $comp already "can" method "$name"} if $comp->can($name);
      $self->install_attr($comp, $name, $attrs{$name}->@*);
    }
    foreach my $name (keys %methods) {
      next if $self->data->{$comp}{override}{$name};
      croak qq{Component $comp already "can" method "$name"} if $comp->can($name);
      monkey_patch $comp, $name, $methods{$name};
    }
    push @hslots, [$comp, [$rex->hooks($role)]];
  }

  foreach my $slot (@hslots) {
    my ($comp, @hooks) = ($slot->[0], $slot->[1]->@*);
    $_->($comp) for @hooks;
  }
}

# ---- funcs ---

sub gen_check_ro($name) {
  sub { croak qq#Attribute "$name" is readonly#; }
}

sub process_is($name, %res) {
  my $is = delete($res{is}) || 'rw';
  croak qq#invalid "is": "$is"# unless $is eq 'ro' || $is eq 'rw';

  $res{check} = gen_check_ro($name) if $is eq 'ro';    # ro replaces check
  return %res;
}

sub _scalar_or_code($opts, $what) {
  croak qq#"$what" should be either a code reference or a scalar value#
    if ref $opts->{$what} && ref $opts->{$what} ne 'CODE';
}


1;
