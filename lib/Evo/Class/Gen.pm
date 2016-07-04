package Evo::Class::Gen;
use Evo '/::Common::Util; Carp croak';

use Hash::Util::FieldHash 'fieldhash';
fieldhash my %DATA;

sub gen_init($class) {
  sub ($class, $obj, %opts) {
    $DATA{$obj} = [];
    bless $obj, $class;
  };
}

sub new ($me) { bless {ai => 0, attrs => {}}, $me; }

sub gen_attr ($self, $name, %opts) {
  croak qr{Attribute "$name" was already generated} if exists $self->{attrs}{$name};

  # gen attr index
  my $index = $self->{ai}++;
  $self->{attrs}{$name} = {%opts, index => $index};

  # closure
  my ($ro, $lazy, $check) = @opts{qw(ro lazy check)};

  # simplest and popular
  if (!$ro && !$lazy && !$check) {
    return sub {
      return $DATA{$_[0]}[$index] if @_ == 1;
      $DATA{$_[0]}[$index] = $_[1];
      $_[0];
    };
  }

  # more complex. we can optimize it by splitting to 6 other. but better use XS
  return sub {
    if (@_ == 1) {
      return $DATA{$_[0]}[$index] if !$lazy;
      return $DATA{$_[0]}[$index] if exists $DATA{$_[0]}[$index];
      return $DATA{$_[0]}[$index] = $lazy->($_[0]);
    }
    croak qq{Attribute "$name" is readonly} if $ro;
    if ($check) {
      my ($ok, $msg) = $check->($_[1]);
      Evo::Class::Common::Util::croak_bad_value($_[1], $name, $msg) unless $ok;
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
