package MyClassOut;
use Evo '-Class::Out *';

overrides qw(overriden1 overriden2);

with 'MyClass::MyRole';

has 'bar';

sub rmethod { }

sub overriden1                {'OVER1'}
sub overriden2                {'OVER2'}
sub overriden3 : Override     {'OVER3'}
sub overriden_attr : Override {'OVER4'}

1;
