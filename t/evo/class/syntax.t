use Evo 'Test::More; -Class::Syntax *; -Internal::Exception';

STATE: {
  is rw, SYNTAX_STATE;
  ok SYNTAX_STATE->{rw};
  like exception {rw}, qr/syntax error: "rw" already/;

  is optional, SYNTAX_STATE;
  ok SYNTAX_STATE->{optional};
  like exception {optional}, qr/syntax error: "optional" already/;

  my $sub = sub {33};
  is check $sub, SYNTAX_STATE;
  is SYNTAX_STATE->{check}, $sub;
  like exception { check $sub }, qr/syntax error: "check" already/;

  is inject '.foo', SYNTAX_STATE;
  is SYNTAX_STATE->{inject}, '.foo';
  like exception { inject '.foo' }, qr/syntax error: "inject" already/;

  is lazy, SYNTAX_STATE;
  ok SYNTAX_STATE->{lazy};
  like exception {lazy}, qr/syntax error: "lazy" already/;

  is keys({syntax_reset}->%*), 5;
  is_deeply SYNTAX_STATE, {};
}


done_testing;
