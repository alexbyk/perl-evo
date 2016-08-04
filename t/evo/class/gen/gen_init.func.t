package main;
use Evo 'Test::More; -Internal::Exception;-Class::Meta; -Class::Gen';


sub parse { Evo::Class::Meta->parse_attr(@_) }
my $FILE = __FILE__;

my $positive = sub($v) { $v > 0 ? 1 : (0, 'OOPS') };


sub test_gen ($gclass) {

  my $gen;

  like exception { $gclass->new->gen_init()->('My::Class', "NOT A REF"); }, qr/ref.+$0/;

  my $init = sub { $gen->gen_init()->('My::Class', {}, @_) };
  my $new = sub { $gen->gen_new()->('My::Class', @_) };
  foreach my $build ($init, $new) {

  SIMPLE: {
      $gen = $gclass->new;
      $gen->gen_attr(simple => parse is => 'rw');

      my $val = 333;
      my $obj = $build->(simple => $val);
      $val = 'bad';
      is_deeply [$gen->gen_attrs_map()->($obj)], ['simple', 333];
    }

  REQUIRED: {
      $gen = $gclass->new;
      $gen->gen_attr(req => parse required => 1);
      like exception { $build->() }, qr#"req" is required.+$0#;
    }

  UNKNOWN: {
      $gen = $gclass->new;
      like exception { $build->(bad => 1) }, qr#Unknown.+"bad".+$0#;
    }

  CHECK: {
  # check if passed but bypass checking of default value, even if it's negative
      $gen = $gclass->new;
      my $sub = $gen->gen_attr(foo => parse default => 0, check => $positive);
      like exception { $build->(foo => 0) }, qr#Bad value.+"0".+"foo".+OOPS.+$0#i;
      is_deeply [$gen->gen_attrs_map()->($build->())], [foo => 0];
    }

  DEFAULT_VALUE: {
      $gen = $gclass->new;
      my $val = 222;
      my $sub = $gen->gen_attr(foo => parse default => $val);
      $val = 'bad';
      is_deeply [$gen->gen_attrs_map()->($build->())], [foo => 222];
      is_deeply [$gen->gen_attrs_map()->($build->(foo => 333))], [foo => 333];
    }

  DEFAULT_UNDEF: {
      $gen = $gclass->new;
      my $sub = $gen->gen_attr(foo => parse default => undef);
      is_deeply [$gen->gen_attrs_map()->($build->())], [foo => undef];
      is_deeply [$gen->gen_attrs_map()->($build->(foo => 333))], [foo => 333];
    }

  DEFAULT_CODE: {
      $gen = $gclass->new;
      my $def = sub($class) { is $class, 'My::Class'; 222 };
      my $sub = $gen->gen_attr(foo => parse default => $def);
      is_deeply [$gen->gen_attrs_map()->($build->())], [foo => 222];
      is_deeply [$gen->gen_attrs_map()->($build->(foo => 333))], [foo => 333];
    }

  }
}

test_gen('Evo::Class::Gen');

done_testing;
