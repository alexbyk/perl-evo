package Evo::Class::Attrs::PP;
use Evo '-Export; Carp croak confess';
use constant {ECA_SIMPLE => 0, ECA_DEFAULT => 1, ECA_DEFAULT_CODE => 2, ECA_REQUIRED => 3,
  ECA_LAZY => 4,};

export qw(
  ECA_SIMPLE ECA_DEFAULT ECA_DEFAULT_CODE ECA_REQUIRED ECA_LAZY
);

my sub _croak_bad_value ($val, $name, $msg) {
  $msg //= '';
  croak qq{Bad value "$val" for attribute "$name": $msg};
}

sub new { bless [], shift }


sub exists ($self, $name) {
  do { return 1 if $_->[0] eq $name }
    for @$self;
  return;
}

sub slots ($self) {
  map {
    my %hash;
    @hash{qw(name type value check ro inject)} = @$_;
    \%hash;
  } @$self;
}

sub list_names($self) {
  map { $_->[0] } @$self;
}

my sub _find_index ($self, $name) {
  my $index = 0;
  do { last if $_->[0] eq $name; $index++ }
    for @$self;
  $index;
}

sub _reg_attr ($self, $name, $type, $value, $check, $ro, $inject) {
  $self->[_find_index($self, $name)] = my $attr = [$name, $type, $value, $check, $ro, $inject];
}

sub _gen_attr ($self, $name, $lazy, $check, $ro) {

  # simplest and popular
  if (!$ro && !$lazy && !$check) {
    return sub {
      return $_[0]{$name} if @_ == 1;
      $_[0]{$name} = $_[1];
      $_[0];
    };
  }

  # more complex. we can optimize it by splitting to 6 other. but better use XS
  return sub {
    if (@_ == 1) {
      return $_[0]{$name} if exists $_[0]{$name};
      return unless $lazy;
      return $_[0]{$name} = $lazy->($_[0]);
    }
    croak qq{Attribute "$name" is readonly} if $ro;
    if ($check) {
      my ($ok, $msg) = $check->(my $val = $_[1]);
      _croak_bad_value($val, $name, $msg) if !$ok;
    }
    $_[0]{$name} = $_[1];
    $_[0];
  };
}

sub gen_attr ($self, $name, $type, $value, $check, $ro, $inject) {
  $self->_reg_attr($name, $type, $value, $check, $ro, $inject);
  $self->_gen_attr($name, $type == ECA_LAZY ? $value : undef, $check, $ro);
}


sub gen_new($self) {

  sub ($class, %opts) {

    my $obj = {};

    # iterate known attrs
    foreach my $slot (@$self) {
      my ($name, $type, $value, $check) = @$slot;

      if (exists $opts{$name}) {
        if ($check) {
          my ($ok, $err) = $check->(my $val = $opts{$name});
          _croak_bad_value($opts{$name}, $name, $err) if !$ok;
        }
        $obj->{$name} = delete $opts{$name};
        next;
      }

      # required and default are mutually exclusive
      if ($type == ECA_REQUIRED) {
        croak qq#Attribute "$name" is required#;
      }
      elsif ($type == ECA_DEFAULT) {
        $obj->{$name} = $value;
      }
      elsif ($type == ECA_DEFAULT_CODE) {
        $obj->{$name} = $value->($class);
      }

      delete $opts{$name};
    }

    croak "Unknown attributes: " . join(',', keys %opts) if (keys %opts);

    bless $obj, $class;
  };
}


1;
