use Evo '-Class::Gen::Hash GEN';
use Test::More;
use Test::Fatal;

my $GEN = GEN;


my $POSITIVE = sub { return 1 if shift > 0; (0, "OOPS!") };

OVERWRITE_CLASS: {
  my $new = $GEN->{new}->('MyClass', {});
  isa_ok $new->(), 'MyClass';
  isa_ok $new->('My::Over'), 'My::Over';
  isa_ok $new->(), 'MyClass';
}

RDCH: {

  my $new = $GEN->{new}->(
    'MyClass',
    {
      known    => {foo => 1, bar => 1, req => 1, dv => 1, dfn => 1, with_check => 1},
      required => ['req'],
      dv  => {dv => 'DV'},
      dfn => {
        dfn => sub { fail if @_; "DFN"; }
      },
      check => {with_check => $POSITIVE}
    }
  );

  like exception { $new->() }, qr#"req" is required.+$0#;
  like exception { $new->(opa => 1, req => 1) }, qr#Unknown.+"opa".+$0#;
  like exception { $new->(with_check => -11, req => 1) },
    qr#Bad value.+"-11".+"with_check".+OOPS!.+$0#i;

  my $obj = $new->(req => 1, foo => 2);
  is_deeply $obj, {req => 1, foo => 2, dv => 'DV', dfn => 'DFN'};

  my $obj2 = $new->(req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10);
  is_deeply $obj2, {req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10};
}

# required default value doesn't need to pass check
RDCH_SPECIAL: {
  my $new = $GEN->{new}->(
    'MyClass',
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

  is_deeply $new->(), {dv => -1, dfn => -2};
}

# check that option is passed by ref and changint it affects builder too
BY_REF: {
  my $bopts = {known => {dv => 1}, required => [], dv => {dv => 'v1'}, dfn => {}, check => {}};
  my $new = $GEN->{new}->('My::Class', $bopts);
  is_deeply $new->(), {dv => 'v1'};
  $bopts->{dv}{dv} = 'v2';
  is_deeply $new->(), {dv => 'v2'};
}

done_testing;
