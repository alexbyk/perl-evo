package main;
use Evo 'Test::More; Evo::Di; Evo::Class::Meta; Evo::Class::Syntax *';
use Module::Loaded qw(mark_as_loaded is_loaded);
use Symbol 'delete_package';

mark_as_loaded('My::Class');

sub reset_class($class = 'My::Class') {
  delete_package $class;
  eval "package $class; use Evo -Class";    ## no critic
  $class->META;
}


BUILD: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();
  $di->{di_stash} = {'My::Existing' => 'BAR', 'My::Existing/Required' => 'BAZ'};
  $meta->reg_attr('foo', inject 'My::Missing',  optional);
  $meta->reg_attr('bar', inject 'My::Existing', optional);
  $meta->reg_attr('baz', inject 'My::Existing/Required');
  my $obj = $di->_di_build('My::Class');
  is_deeply $obj, {bar => 'BAR', baz => 'BAZ'};
  isnt $di->_di_build('My::Class'), $obj;
}

BUILD_DOTS: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();
  $meta = reset_class();

  My::Class->new();
  $di->{di_stash} = {'My::Class.' => {foo => 'FOO'}};

  $meta->reg_attr('foo', inject '.foo');
  $meta->reg_attr('missing', inject '.missing', optional);
  my $obj = $di->_di_build('My::Class');
  is_deeply $obj,                          {foo => 'FOO'};
  is_deeply $di->{di_stash}{'My::Class.'}, {foo => 'FOO'};
}

ALL_MISSING: {
  my $di   = Evo::Di->new();
  my $meta = reset_class();
  $meta = reset_class();

  My::Class->new();
  $meta->reg_attr('foo', inject '.foo', optional);
  $meta->reg_attr('missing', inject '.missing', optional);
  ok my $obj = $di->_di_build('My::Class');
  is_deeply $di->{di_stash}, {};    # not spoiled
}

done_testing;
