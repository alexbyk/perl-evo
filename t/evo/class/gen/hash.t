use Evo '-Class::Gen::Hash GEN';
use Test::More;
use Test::Evo::Helpers "exception";

my $GEN = GEN;

GS: {
  my $obj = {};
  my $gs  = $GEN->{gs}->('foo');
  is $gs->($obj, 0), $obj;
  is_deeply $obj, {foo => 0};
  is $gs->($obj), 0;
}


GS_VALUE: {
  my $obj = {};
  my $gs = $GEN->{gs_value}->('foo', 'DEFAULT');
  is $gs->($obj), 'DEFAULT';
  is_deeply $obj, {};
  is $gs->($obj, 0), $obj;
  is_deeply $obj, {foo => 0};
  is $gs->($obj), 0;
}

GS_CODE: {
  my $obj = {};
  my $fn  = sub { is $_[0], $obj; 'FN' };
  my $gs  = $GEN->{gs_code}->('foo', $fn);
  is $gs->($obj), 'FN';
  is_deeply $obj, {};
  is $gs->($obj, 0), $obj;
  is_deeply $obj, {foo => 0};
  is $gs->($obj), 0;
}

my $check = sub { $_[0] > 0 ? (1) : (0, "Ooops") };

GSCH: {
  my $obj = {foo => 33};
  my $gsch = $GEN->{gsch}->('foo', $check);

  # get
  is $gsch->($obj), 33;

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}

GSCH_VALUE: {
  my $obj = {};
  my $gsch = $GEN->{gsch_value}->('foo', $check, 'DEFAULT');

  # get
  is $gsch->($obj), 'DEFAULT';

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}

GSCH_CODE: {
  my $obj  = {};
  my $fn   = sub { is $_[0], $obj; 'FN' };
  my $gsch = $GEN->{gsch_code}->('foo', $check, $fn);

  # get
  is $gsch->($obj), 'FN';

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}

done_testing;
