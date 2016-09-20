package Evo::Class::Attrs;
use Evo -Export;

our $IMPL
  = eval { require Evo::Class::Attrs::XS; 1 } ? 'Evo::Class::Attrs::XS' : 'Evo::Class::Attrs::PP';

export_proxy $IMPL, '*';
our @ISA = ($IMPL);

1;
