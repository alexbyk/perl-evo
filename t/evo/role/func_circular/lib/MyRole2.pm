package MyRole2;
use Evo;
use Evo::Role '*';

requires qw(rmethod a1 m1);
has 'a2' => 'a2val';
sub m2 : Role { }

1;
