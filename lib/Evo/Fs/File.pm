package Evo::Fs::File;
use Evo '-Class *, -new', 'File::Spec; File::Basename(); Symbol()';

has 'fs', is => 'ro';
has path => is => 'ro', required => 1, check => sub($v) { File::Spec->file_name_is_absolute($v) };

sub new { shift->init(Symbol::gensym(), @_); }
sub name($self) { scalar File::Basename::fileparse($self->path); }

1;
