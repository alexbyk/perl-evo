package main;
use Evo 'Test::More; Evo::Di; Evo::Class::Meta';
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
  $meta->reg_attr('foo', inject => 'My::Missing');
  $meta->reg_attr('bar', inject => 'My::Existing');
  $meta->reg_attr('baz', inject => 'My::Existing/Required', required => 1);
  my $obj = $di->_di_build('My::Class');
  is $obj->bar, 'BAR';
  is $obj->baz, 'BAZ';
  ok !exists $obj->{foo};

  isnt $di->_di_build('My::Class'), $obj;
}

done_testing;
