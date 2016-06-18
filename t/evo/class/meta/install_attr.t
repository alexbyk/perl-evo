package main;
use Evo 'Evo::Class::Meta; Test::More; Test::Evo::Helpers exception; Test::Evo::Helpers *';

no warnings 'redefine';
my $called;
local *Evo::Class::Meta::monkey_patch = sub { $called++ };

my $meta = dummy_meta();
$meta->install_attr('myro', is => 'ro');
$meta->install_attr('myrw', is => 'rw');

ok $meta->builder_options->{known}{myro};
ok $meta->builder_options->{known}{myrw};
is { $meta->public_attrs }->{myro}{is}, 'ro';
is { $meta->public_attrs }->{myrw}{is}, 'rw';


$meta->install_attr('mydef', 'val');
ok $meta->builder_options->{known}{mydef};
is { $meta->public_attrs }->{mydef}{default}, 'val';

is $called, 3;
done_testing;
