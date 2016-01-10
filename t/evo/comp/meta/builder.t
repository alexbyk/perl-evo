use Evo;
use Evo::Comp::Meta;
use Test::More;


BUILDER_OPTIONS: {
  my $meta = Evo::Comp::Meta::new();
  my $bo   = $meta->builder_options('MyComp');
  is $bo , $meta->builder_options('MyComp');
}

my $noop = sub { };

CONVERT_FOR_BUILDER_ALL: {

  my $meta = Evo::Comp::Meta::new();
  $meta->data->{MyComp}{attrs} = {
    req        => {required => 1},
    simple     => {},
    dv         => {default  => 0},
    dfn        => {default  => $noop},
    with_check => {check    => 'CH'}
  };

  $meta->update_builder_options('MyComp');
  my $shape = $meta->builder_options('MyComp');

  is_deeply $shape->{known}, {(req => 1, simple => 1, dv => 1, dfn => 1, with_check => 1)};
  is_deeply [sort $shape->{required}->@*], [sort qw(req)];
  is_deeply $shape->{dv},    {dv         => 0};
  is_deeply $shape->{dfn},   {dfn        => $noop};
  is_deeply $shape->{check}, {with_check => 'CH'};
}

CONVERT_FOR_BUILDER_RESET: {
  my $meta = Evo::Comp::Meta::new();
  $meta->data->{MyComp}{attrs} = {req => {}};

  $meta->update_builder_options('MyComp');
  my $shape = $meta->builder_options('MyComp');

  is_deeply $shape, {known => {req => 1}, required => [], dv => {}, dfn => {}, check => {}};

  #reset
  $meta->data->{MyComp}{attrs} = {};
  $meta->update_builder_options('MyComp');
  is_deeply $shape, {known => {}, required => [], dv => {}, dfn => {}, check => {}};

}

my $gen = {
  new => sub {
    my $str = join ',', @_;
    sub {$str}
  }
};
COMPILE: {
  my $meta = Evo::Comp::Meta::new(gen => $gen);

  my $called;
  no warnings 'redefine';
  local *Evo::Comp::Meta::update_builder_options = sub { $called++ };

  $meta->data->{'MyComp'}{bo} = 'MYBO';
  is $meta->compile_builder('MyComp')->(), 'MyComp,MYBO';
  is $called, 1;
}

COMPILE_FIRST: {
  my $meta = Evo::Comp::Meta::new(gen => $gen);
  like $meta->compile_builder('MyComp')->(), qr/MyComp/;
}

done_testing;
