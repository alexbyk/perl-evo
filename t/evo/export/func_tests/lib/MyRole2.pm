package MyRole2;
use Evo '-Export *';
export 'm2';
export_requires 'm1';

sub m2 {2}

1;
