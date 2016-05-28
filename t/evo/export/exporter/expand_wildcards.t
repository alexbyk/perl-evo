use Evo -Export::Class;
use Test::More;
use Test::Fatal;

my $obj = Evo::Export::Class->new();
$obj->add_gen('Lib', 'f1', 'GEN');
$obj->add_gen('Lib', 'f2', 'GEN');
$obj->add_gen('Lib', 'f3', 'GEN');


is_deeply [$obj->expand_wildcards('Lib', 'f3', '*', 'f2')], [qw(f1 f2 f3)];

is_deeply [$obj->expand_wildcards('Lib', '*', '-f1')], [qw(f2 f3)];

like exception { $obj->expand_wildcards('Not::Existing', '*') },
  qr/Not::Existing exports nothing.+$0/;

like exception { $obj->expand_wildcards('Lib') }, qr/empty list.+$0/i;

done_testing;
