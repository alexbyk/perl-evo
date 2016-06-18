use Evo -Export::Class;
use Test::More;
use Test::Evo::Helpers "exception";

my $obj = Evo::Export::Class->new();

my $counter = 0;
$obj->add_gen(
  'Lib', 'name',
  sub {
    my $local_counter = ++$counter;
    sub {$local_counter}
  }
);

# the same function for same module, other for other module
my $fn       = $obj->request_gen('Lib', 'name', 'Dest');
my $fn_same  = $obj->request_gen('Lib', 'name', 'Dest');
my $fn_other = $obj->request_gen('Lib', 'name', 'Other');
is $fn->(), 1;
is $fn,   $fn_same;
isnt $fn, $fn_other;
is $fn_other->(), 2;

# proxy
$obj->add_proxy('Proxy', 'pname', 'Lib', 'name');

is $obj->request_gen('Proxy', 'pname', 'Dest'), $fn;

done_testing;
