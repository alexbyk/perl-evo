use Evo '-Class::Gen::Hash GEN';
use Test::More;
use Test::Fatal;

my $GEN = GEN;


my $POSITIVE = sub { return 1 if shift > 0; (0, "OOPS!") };

OVERWRITE_CLASS: {
  my $new = $GEN->{new}->({});
  isa_ok $new->('MyClass'), 'MyClass';
}

RDCH: {

  my @GOT_DFN;

  my $new = $GEN->{new}->(
    {
      known    => {foo => 1, bar => 1, req => 1, dv => 1, dfn => 1, with_check => 1},
      required => ['req'],
      dv  => {dv => 'DV'},
      dfn => {
        dfn => sub { is_deeply \@_, [qw(req 1 foo 2)]; "DFN"; }
      },
      check => {with_check => $POSITIVE}
    }
  );

  like exception { $new->('MyClass',) }, qr#"req" is required.+$0#;
  like exception { $new->('MyClass', opa => 1, req => 1) }, qr#Unknown.+"opa".+$0#;
  like exception { $new->('MyClass', with_check => -11, req => 1) },
    qr#Bad value.+"-11".+"with_check".+OOPS!.+$0#i;

  my $obj = $new->('MyClass', req => 1, foo => 2);
  is_deeply $obj, {req => 1, foo => 2, dv => 'DV', dfn => 'DFN'};

  my $obj2 = $new->('MyClass', req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10);
  is_deeply $obj2, {req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10};

}

# required default value doesn't need to pass check
RDCH_SPECIAL: {
  my $new = $GEN->{new}->(
    {
      known    => {dv => 1, dfn => 1},
      required => [],
      dv  => {dv => -1},
      dfn => {
        dfn => sub { fail if @_; -2 }
      },
      check => {dv => $POSITIVE, dfn => $POSITIVE}
    }
  );

  is_deeply $new->('MyClass',), {dv => -1, dfn => -2};
}

# check that option is passed by ref and changint it affects builder too
BY_REF: {
  my $bopts = {known => {dv => 1}, required => [], dv => {dv => 'v1'}, dfn => {}, check => {}};
  my $new = $GEN->{new}->($bopts);
  is_deeply $new->('MyClass',), {dv => 'v1'};
  $bopts->{dv}{dv} = 'v2';
  is_deeply $new->('MyClass',), {dv => 'v2'};
}

done_testing;
