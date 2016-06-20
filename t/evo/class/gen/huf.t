use Evo '-Class::Gen::HUF GEN';
use Test::More;
use Test::Evo::Helpers "exception";

my $GEN = GEN;

sub closure {
  my $fee;
  sub {$fee};
}

GS: {
  my $obj = closure();
  my $gs  = $GEN->{gs}->('foo');
  is $gs->($obj, 0), $obj;
  is $gs->($obj), 0;
}

GS_VALUE: {
  my $obj = closure();
  my $gs = $GEN->{gs_value}->('foo', 'DEFAULT');
  is $gs->($obj), 'DEFAULT';
  is $gs->($obj, 0), $obj;
  is $gs->($obj), 0;
}

GS_CODE: {
  my $obj = closure();
  my $i   = 1;
  my $fn  = sub { is $_[0], $obj; 'FN' . $i++ };
  my $gs  = $GEN->{gs_code}->('foo', $fn);
  is $gs->($obj), $gs->($obj);    # same value
  is $gs->($obj), 'FN1';
  is $gs->($obj, 0), $obj;
  is $gs->($obj), 0;
}


my $check = sub { $_[0] > 0 ? (1) : (0, "Ooops") };

GSCH: {
  my $obj = closure();
  my $gsch = $GEN->{gsch}->('foo', $check);

  # get
  $gsch->($obj);

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}

GSCH_VALUE: {
  my $obj = closure();
  my $gsch = $GEN->{gsch_value}->('foo', $check, 'DEFAULT');

  # get
  is $gsch->($obj), 'DEFAULT';

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}

GSCH_CODE: {
  my $obj  = closure();
  my $i    = 1;
  my $fn   = sub { is $_[0], $obj; 'FN' . $i++ };
  my $gsch = $GEN->{gsch_code}->('foo', $check, $fn);

  # get
  is $gsch->($obj), $gsch->($obj);    # same value
  is $gsch->($obj), 'FN1';

  # set
  is $gsch->($obj, 11), $obj;
  is $gsch->($obj), 11;
  like exception { $gsch->($obj, -22), $obj; }, qr/bad value "-22".+"foo".+Ooops/i;
}


is_deeply Evo::Class::Gen::HUF::HUF_DATA(), {};

use Data::Dumper;

done_testing;
