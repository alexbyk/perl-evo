use Evo;
use Evo::Class::Meta;
use Test::More;


BUILDER_OPTIONS: {
  my $meta = Evo::Class::Meta::new();
  my $bo   = $meta->builder_options('MyClass');
  is $bo , $meta->builder_options('MyClass');
}

my $noop = sub { };

CONVERT_FOR_BUILDER_ALL: {

  my $meta = Evo::Class::Meta::new();
  $meta->data->{MyClass}{attrs} = {
    req        => {required => 1},
    simple     => {},
    dv         => {default  => 0},
    dfn        => {default  => $noop},
    with_check => {check    => 'CH'}
  };

  $meta->update_builder_options('MyClass');
  my $shape = $meta->builder_options('MyClass');

  is_deeply $shape->{known}, {(req => 1, simple => 1, dv => 1, dfn => 1, with_check => 1)};
  is_deeply [sort $shape->{required}->@*], [sort qw(req)];
  is_deeply $shape->{dv},    {dv         => 0};
  is_deeply $shape->{dfn},   {dfn        => $noop};
  is_deeply $shape->{check}, {with_check => 'CH'};
}

CONVERT_FOR_BUILDER_RESET: {
  my $meta = Evo::Class::Meta::new();
  $meta->data->{MyClass}{attrs} = {req => {}};

  $meta->update_builder_options('MyClass');
  my $shape = $meta->builder_options('MyClass');

  is_deeply $shape, {known => {req => 1}, required => [], dv => {}, dfn => {}, check => {}};

  #reset
  $meta->data->{MyClass}{attrs} = {};
  $meta->update_builder_options('MyClass');
  is_deeply $shape, {known => {}, required => [], dv => {}, dfn => {}, check => {}};

}

my $gen = {
  new => sub {
    my $str = join ',', @_;
    sub {$str}
  }
};
COMPILE: {
  my $meta = Evo::Class::Meta::new(gen => $gen);

  my $called;
  no warnings 'redefine';
  local *Evo::Class::Meta::update_builder_options = sub { $called++ };

  $meta->data->{'MyClass'}{bo} = 'MYBO';
  is $meta->compile_builder('MyClass')->(), 'MyClass,MYBO';
  is $called, 1;
}

COMPILE_FIRST: {
  my $meta = Evo::Class::Meta::new(gen => $gen);
  like $meta->compile_builder('MyClass')->(), qr/MyClass/;
}

done_testing;
