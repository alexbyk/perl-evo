use Evo '-Eval *; -Want *';
use Test::More;

my ($wanted);
my $spy = sub {
  $wanted = wantarray;
  return 'UNDEF' unless defined $wanted;
  return $wanted ? (4, 5, 6) : (33);
};

my $die = sub { die "Foo\n"; };

# inc to know if passed by ref
my $inc = sub { $_++ for @_ };

WANT_VOID: {
  my $call = eval_want(WANT_VOID, $spy);
  ok want_is_void($wanted);
  ok want_is_void($call->{wanted});
  is $call->result, undef;
}

WANT_SCALAR: {
  my $call = eval_want(WANT_SCALAR, $spy);
  ok want_is_scalar($wanted);
  ok want_is_scalar($call->{wanted});
  is $call->result, 33;
}

WANT_SCALAR: {
  my $call = eval_want(WANT_LIST, $spy);
  ok want_is_list($wanted);
  ok want_is_list($call->{wanted});
  is_deeply [$call->result], [4, 5, 6];
}

# die
DIE: {
  is eval_want(WANT_VOID, $die), undef;
  is $@, "Foo\n";

  is eval_want(WANT_SCALAR, $die), undef;
  is $@, "Foo\n";

  is eval_want(WANT_LIST, $die), undef;
  is $@, "Foo\n";
}

# die
ARGS: {
  my @args = (10, 20);
  ok eval_want WANT_VOID, @args, $inc;
  is_deeply \@args, [11, 21];

  ok eval_want WANT_SCALAR, @args, $inc;
  is_deeply \@args, [12, 22];

  ok eval_want WANT_LIST, @args, $inc;
  is_deeply \@args, [13, 23];
}

done_testing;
