package MyRole1;
use Evo;
use Evo::Role '*';

requires qw(rmethod a2 m2);
has 'a1' => 'a1val';
sub m1 : Role { }

1;
