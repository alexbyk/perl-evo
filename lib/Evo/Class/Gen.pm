package Evo::Class::Gen;
use Evo '/::Common::Util; Carp croak';

sub new ($me) {
  bless {
    ai      => 0,
    indexes => {},
    builder => {dv => {}, dfn => {}, check => {}, required => [], known => {}},
  }, $me;
}

sub sync_attr ($self, $name, %o) {
  my $builder = $self->{builder};
  $builder->{known}{$name}++;
  push $builder->{required}->@*, $name if $o{required};
  (ref $o{default} ? $builder->{dfn} : $builder->{dv})->{$name} = $o{default}
    if exists $o{default};
  $builder->{check}{$name} = $o{check} if $o{check};
}

sub gen_attr ($self, $name, %opts) {

  # before anything else
  croak qr{Attribute "$name" was already generated} if exists $self->{indexes}{$name};

  $self->sync_attr($name, %opts);
  %opts = Evo::Class::Common::Util::process_is($name, %opts);    # change rw to check
  my ($type, @args) = Evo::Class::Common::Util::compile_attr(%opts);

  # gen attr
  my $index = $self->{indexes}{$name} = $self->{ai}++;
  #$self->$type($name, $index, @args);
}

1;
