package Evo::Class::Gen::Out;
use Evo 'Carp croak';
use parent 'Evo::Class::Common::GenBase';
use parent 'Evo::Class::Common::GenPP';

use Hash::Util::FieldHash 'fieldhash';
fieldhash my %DATA;

sub obj_to_hash ($self, $obj) {
  $DATA{$obj}->%*;
}

sub gen_init($self) {

  my ($known, $required, $dv, $dfn, $check) = @$self{qw(_known _required _dv _dfn _check)};
  sub ($class, $obj, %opts) {
    croak "$obj isn't a ref" unless ref $obj;
    exists $opts{$_} or croak qq#Attribute "$_" is required# for $required->@*;
    foreach my $k (keys %opts) {
      exists $known->{$k} or croak qq#Unknown attribute "$k"#;
      if (exists ${check}->{$k}) {
        my ($ok, $err) = $check->{$k}->($opts{$k});
        Evo::Class::Common::Util::croak_bad_value($opts{$k}, $k, $err) unless $ok;
      }
    }
    exists $opts{$_} or $opts{$_} = $dv->{$_}            for keys $dv->%*;
    exists $opts{$_} or $opts{$_} = $dfn->{$_}->($class) for keys $dfn->%*;

    $DATA{$obj} = \%opts;
    bless $obj, $class;
  };
}

sub gen_gs ($self, $name) {
  sub {
    return $DATA{$_[0]}->{$name} if @_ == 1;
    $DATA{$_[0]}->{$name} = $_[1];
    $_[0];
  };
}

sub gen_gs_code ($self, $name, $code) {
  sub {
    if (@_ == 1) {
      return $DATA{$_[0]}->{$name} if exists $DATA{$_[0]}->{$name};
      return $DATA{$_[0]}->{$name} = $code->($_[0]);
    }
    $DATA{$_[0]}->{$name} = $_[1];
    $_[0];
  };
}


sub gen_gsch ($self, $name, $ch) {
  sub {
    return $DATA{$_[0]}->{$name} if @_ == 1;
    my ($ok, $msg) = $ch->($_[1]);
    Evo::Class::Common::Util::croak_bad_value($_[1], $name, $msg) unless $ok;
    $DATA{$_[0]}->{$name} = $_[1];
    $_[0];
  };
}


sub gen_gsch_code ($self, $name, $ch, $code) {
  sub {
    if (@_ == 1) {
      return $DATA{$_[0]}->{$name} if exists $DATA{$_[0]}->{$name};
      return $DATA{$_[0]}->{$name} = $code->($_[0]);
    }
    my ($ok, $msg) = $ch->($_[1]);
    Evo::Class::Common::Util::croak_bad_value($_[1], $name, $msg) unless $ok;
    $DATA{$_[0]}->{$name} = $_[1];
    $_[0];
  };
}

sub gen_attr_exists ($self) {
  sub ($obj, $name) {
    exists $DATA{$obj}{$name};
  };
}

sub gen_attr_delete ($self) {
  sub ($obj, $name) {
    delete $DATA{$obj}{$name};
  };
}

1;
