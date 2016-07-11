package Evo::Fs::Dir;
use Evo -Class, 'File::Spec; File::Basename()';

has 'fs', is => 'ro';
has path => required => 1, check => sub($v) { File::Spec->file_name_is_absolute($v) };
sub name($self) { scalar File::Basename::fileparse($self->path); }

1;
