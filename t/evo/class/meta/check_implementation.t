use Evo '-Class::Meta; Test::More; Test::Evo::Helpers exception; Test::Evo::Helpers *';

no warnings qw(once redefine );

EMPTY: {
  like exception { dummy_meta->check_implementation(dummy_meta('My::Ch')) }, qr/Empty/;
}

my $inter = dummy_meta('My::Inter');
my $meta  = dummy_meta('My::Class');

$inter->reg_requirement('foo');
$inter->reg_requirement('bar');

like exception { $meta->check_implementation($inter); }, qr/bar;foo.+$0/;


no warnings 'once';
local *My::Class::foo = sub { };
local *My::Class::bar = sub { };
ok eval { $meta->check_implementation($inter); 1 };

done_testing;
