use Evo '-Class::Meta; Test::More; Test::Evo::Helpers dummy_meta';


BUILDER_OPTIONS: {
  my $meta    = dummy_meta;
  my $prev_bo = $meta->builder_options();
  $meta->update_builder_options();
  is $prev_bo , $meta->builder_options();
}

my $noop = sub { };

CONVERT_FOR_BUILDER_ALL: {

  my $meta = dummy_meta;
  $meta->reg_attr(req => required => 1);
  $meta->reg_attr('simple');
  $meta->reg_attr(dv         => default => 0);
  $meta->reg_attr(dfn        => default => $noop);
  $meta->reg_attr(with_check => check   => 'CH');

  $meta->update_builder_options();
  my $shape = $meta->builder_options();

  is_deeply $shape->{known}, {(req => 1, simple => 1, dv => 1, dfn => 1, with_check => 1)};
  is_deeply [sort $shape->{required}->@*], [sort qw(req)];
  is_deeply $shape->{dv},    {dv         => 0};
  is_deeply $shape->{dfn},   {dfn        => $noop};
  is_deeply $shape->{check}, {with_check => 'CH'};
}


COMPILE: {
  my $meta = dummy_meta;

  my $called;
  no warnings 'redefine';
  local *Evo::Class::Meta::update_builder_options = sub { $called++ };

  $meta->{_bo} = 'MYBO';
  my $init;
  $init = $meta->compile_builder() for 1 .. 2;
  is $init, $meta->compile_builder();
  is $init->(), 'MYBO';
  is $called, 1, "Second time use cash";

  $meta->reg_attr('simple');
  is $meta->compile_builder()->(), 'MYBO';
  is $called, 2;
}

done_testing;
