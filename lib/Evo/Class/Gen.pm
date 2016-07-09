package Evo::Class::Gen;
use Evo 'Carp croak; -Class::Meta';

use List::Util 'first';
use Hash::Util::FieldHash 'fieldhash';
fieldhash my %DATA;

my sub _croak_bad_value ($val, $name, $msg) {
  $msg //= '';
  croak qq{Bad value "$val" for attribute "$name": $msg};
}


sub gen_init($self) {
  my $attrs = $self->{attrs};
  sub ($class, $obj, %opts) {
    croak "Not a reference" unless ref $obj;
    my @arr;

    # iterate passed args and fill @arr
    foreach my $k (keys %opts) {
      exists $attrs->{$k} && exists $attrs->{$k}{index} or croak qq#Unknown attribute "$k"#;
      my $index = $attrs->{$k}{index};
      if (my $check = $attrs->{$k}{check}) {
        my ($ok, $err) = $check->($opts{$k});
        _croak_bad_value($opts{$k}, $k, $err) if !$ok;
      }
      @arr[$index] = $opts{$k};
    }

    # iterate known attrs
    foreach my $k (keys %$attrs) {
      my $index = $attrs->{$k}{index};
      next if exists $arr[$index];

      # required and default are mutually exclusive
      if ($attrs->{$k}{rtype} eq 'required') {
        croak qq#Attribute "$k" is required#;
      }
      elsif ($attrs->{$k}{rtype} eq 'default') {
        $arr[$index] = $attrs->{$k}{rvalue};
      }
      elsif ($attrs->{$k}{rtype} eq 'default_code') {
        $arr[$index] = $attrs->{$k}{rvalue}->($class);
      }
    }

    bless $obj, $class;
    $DATA{$obj} = \@arr;
    $obj;
  };
}

sub gen_new($self) {
  my $init = $self->gen_init();
  sub { $init->(shift, {}, @_); };
}

sub new ($me) { bless {ai => 0, attrs => {}}, $me; }

sub gen_attrs_map($self) {
  sub($obj) {
    my @map;
    my $i     = 0;
    my $attrs = $self->{attrs};
    foreach my $key (keys $attrs->%*) {
      my $index = $attrs->{$key}->{index};
      $map[$index * 2] = $key;
      $map[$index * 2 + 1] = $DATA{$obj}->[$index];
    }
    @map;
  };
}

sub reg_attr ($self, $name, $attr) {

  # gen attr index
  my $index = exists $self->{attrs}{$name} ? $self->{attrs}{$name}{index} : $self->{ai}++;
  $self->{attrs}{$name} = {%$attr, index => $index};
  $index;
}

sub gen_attr ($self, $name, $attr) {
  $self->reg_attr($name, $attr);
  $self->gen_attr_code($name);
}


sub gen_attr_code ($self, $name) {

  # closure
  my $attr = $self->{attrs}{$name};
  my ($rtype, $rvalue, $check, $index) = @$attr{qw(rtype rvalue check index)};
  my $is_ro   = $attr->{ro};
  my $is_lazy = $attr->{rtype} eq 'lazy';

  # simplest and popular
  if (!$is_ro && !$is_lazy && !$check) {
    return sub {
      return $DATA{$_[0]}[$index] if @_ == 1;
      $DATA{$_[0]}[$index] = $_[1];
      $_[0];
    };
  }

  # more complex. we can optimize it by splitting to 6 other. but better use XS
  return sub {
    if (@_ == 1) {
      return $DATA{$_[0]}[$index] if !$is_lazy;
      return $DATA{$_[0]}[$index] if exists $DATA{$_[0]}[$index];
      return $DATA{$_[0]}[$index] = $rvalue->($_[0]);
    }
    croak qq{Attribute "$name" is readonly} if $is_ro;
    if ($check) {
      my ($ok, $msg) = $check->($_[1]);
      _croak_bad_value($_[1], $name, $msg) if !$ok;
    }
    $DATA{$_[0]}[$index] = $_[1];
    $_[0];
  };

}

my sub index_of ($self, $name) {
  croak qq{attribute "$name" wasn't registered } unless exists $self->{attrs}{$name};
  $self->{attrs}{$name}{index};
}

sub gen_attr_exists ($self) {
  sub ($obj, $name) {
    my $index = index_of($self, $name);
    exists $DATA{$obj}[$index];
  };
}

sub gen_attr_delete ($self) {
  sub ($obj, $name) {
    my $index = index_of($self, $name);
    delete $DATA{$obj}[$index];
  };
}

1;
