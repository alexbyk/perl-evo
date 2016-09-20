package Evo::Class::Attrs;
use Evo -Export;

our $IMPL
  = eval { require Evo::Class::Attrs::XS; 1 } ? 'Evo::Class::Attrs::XS' : 'Evo::Class::Attrs::PP';

export_proxy $IMPL, '*';
our @ISA = ($IMPL);

1;

=method gen_attr ($self, $name, $type, $value, $check, $ro)

Register attribute and return an 'attribute' code. C<$type> can be on of

=for :list

* relaxed - simple attr
* default - attr with default C<$value>
* default_code - attr with default value - a result of invocation of the C<$value>
* required - a value that is required
* lazy - like default_code, but C<$value> will be called on demand

=cut

