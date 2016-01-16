package Evo::Io;
use Evo '-Comp::Out *; Symbol gensym';

with ':Role';

sub new() { init(gensym) }


1;
