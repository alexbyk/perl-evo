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

sub new ($me) {
  bless {
    ai      => 0,
    indexes => {},
    builder => {dv => {}, dfn => {}, check => {}, required => [], known => {}},
  }, $me;
}

my sub sync_attr ($self, $name, %o) {
  my $builder = $self->{builder};
  $builder->{known}{$name}++;
  push $builder->{required}->@*, $name if $o{required};
  (ref $o{default} ? $builder->{dfn} : $builder->{dv})->{$name} = $o{default}
    if exists $o{default};
  $builder->{check}{$name} = $o{check} if $o{check};
}

sub gen_attr ($self, $name, %opts) {

  croak qr{Attribute "$name" was already generated} if exists $self->{indexes}{$name};
  sync_attr($self, $name, %opts);

  # gen attr index
  my $index = $self->{indexes}{$name} = $self->{ai}++;

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

  return sub {
    if (@_ == 1) {    # get
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
  croak qq{attribute "$name" wasn't registered } unless exists $self->{indexes}{$name};
  $self->{indexes}{$name};
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
