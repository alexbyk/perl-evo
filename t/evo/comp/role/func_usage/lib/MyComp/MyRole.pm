package MyComp::MyRole;
use Evo;
use Evo::Comp::Role '*';

has 'foo';

role_methods('foo_bar');

role_gen gm => sub {
  my $class = shift;
  sub { $class . $_[1] };
};

requires('rmethod');


sub foo_bar { return $_[0]->foo . $_[0]->bar }

sub FOO_BAR : Role { uc shift->foo_bar }

1;
