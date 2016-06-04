use Evo '-Class::Gen::HUF GEN';
use Test::More;
use Test::Fatal;

*HUF_DATA = *Evo::Class::Gen::HUF::HUF_DATA;

sub closure() {
  my $fee;
  sub {$fee};
}

my $POSITIVE = sub { return 1 if shift > 0; (0, "OOPS!") };

RDCH: {

  my $new = GEN->{init}->(
    'MyClass',
    {
      known    => {foo => 0, bar => 1, req => 2, dv => 3, dfn => 4, with_check => 5},
      required => ['req'],
      dv  => {dv => 'DV'},
      dfn => {
        dfn => sub { is_deeply \@_, [qw(req 1 foo 2)]; "DFN"; }
      },
      check => {with_check => $POSITIVE}
    }
  );

  my $obj = closure();
  like exception { $new->($obj) }, qr#"req" is required.+$0#;
  like exception { $new->($obj, opa => 1, req => 1) }, qr#Unknown.+"opa".+$0#;
  like exception { $new->($obj, with_check => -11, req => 1) },
    qr#Bad value.+"-11".+"with_check".+OOPS!.+$0#i;

  is $new->($obj, req => 1, foo => 2), $obj;
  is_deeply HUF_DATA($obj), {req => 1, foo => 2, dv => 'DV', dfn => 'DFN'};

  my $obj2 = $new->(closure(), req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10);
  is_deeply HUF_DATA($obj2), {req => 1, foo => 2, dv => 3, dfn => 4, with_check => 10};
}

# required default value doesn't need to pass check
RDCH_SPECIAL: {
  my $new = GEN->{init}->(
    'MyClass',
    {
      known    => {dv => 0, dfn => 1},
      required => [],
      dv  => {dv => -1},
      dfn => {
        dfn => sub { fail if @_; -2 }
      },
      check => {dv => $POSITIVE, dfn => $POSITIVE}
    }
  );


  my $obj = $new->(closure());
  is_deeply HUF_DATA($obj), {dv => -1, dfn => -2};
}

done_testing;
