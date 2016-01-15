package MyCompOut;
use Evo '-Comp::Out *';

overrides qw(overriden1 overriden2);

with 'MyComp::MyRole';

has 'bar';

sub rmethod { }

sub overriden1 {'OVER1'};
sub overriden2 {'OVER2'};
sub overriden3 : Override {'OVER3'};

1;
