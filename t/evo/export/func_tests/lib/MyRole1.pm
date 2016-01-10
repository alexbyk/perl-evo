package MyRole1;
use Evo '-Export *';
export 'm1';
export_requires 'm2';

sub m1 {1}

1;
