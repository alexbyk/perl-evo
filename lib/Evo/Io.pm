package Evo::Io::Handle;
use Evo '-Comp::Out *; Symbol gensym';

with ':Role';

sub new() { init(gensym) }


1;
