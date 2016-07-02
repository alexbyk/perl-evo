package Evo::Class::Common::GenPP;
use Evo '-Class::Common::Util; -Internal::Util; Carp croak';

sub new ($me) {
  bless {_dv => {}, _dfn => {}, _check => {}, _required => [], _known => {}}, $me;
}

sub sync_attrs ($self, %attrs) {
  $self->{$_}->%* = () for qw(_known _check _dv _dfn);
  $self->{_required}->@* = ();
  for my $name (keys %attrs) {
    my %o = $attrs{$name}->%*;
    $self->{_known}{$name}++;
    push $self->{_required}->@*, $name if $o{required};
    (ref $o{default} ? $self->{_dfn} : $self->{_dv})->{$name} = $o{default} if exists $o{default};
    $self->{_check}{$name} = $o{check} if $o{check};
  }
}

sub gen_attr ($self, $name, %opts) {
  %opts = Evo::Class::Common::Util::process_is($name, %opts);
  my ($type, @args) = Evo::Class::Common::Util::compile_attr($name, %opts);
  $self->$type(@args);

}

1;
