package Evo::Class::Common::Util;
use Evo 'Carp croak; File::Basename; File::Spec';

our @CARP_NOT = qw(Evo::Class::Gen::In Evo::Class::Gen::Out);

# ro just adds ch wrapper
# example of return: 'gen_gen_gs_value', 'name', 'value'
sub compile_attr ($name, %opts) {
  my $lt   = exists $opts{lazy} && (ref $opts{lazy} ? 'CODE' : 'VALUE');
  my $lazy = $opts{lazy};
  my $ch   = $opts{check};

  my @res;
  if (!$lt) {
    @res = $ch ? ('gen_gsch', $name, $ch) : ('gen_gs', $name);
  }
  elsif ($lt eq 'CODE') {
    @res = $ch ? ('gen_gsch_code', $name, $ch, $lazy) : ('gen_gs_code', $name, $lazy);
  }
  else { croak "Bad type $lt"; }

  @res;
}

sub croak_bad_value ($value, $name, $msg = undef) {
  my $err = qq'Bad value "$value" for attribute "$name"';
  $err .= ": $msg" if $msg;
  croak $err;
}

sub process_is ($name, %res) {
  my $is = delete($res{is});
  $res{check} = sub { croak qq#Attribute "$name" is readonly#; }
    if $is && $is eq 'ro';    # ro replaces check
  return %res;
}

sub register_and_import ($me, @list) {
  my $caller = caller;
  Evo::Class::Meta->register($caller);
  my $gen = $me->class_of_gen->register($caller);
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
}

1;
