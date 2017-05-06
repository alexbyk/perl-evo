package Evo::Class::Base;
use Evo '/::Meta; -Internal::Util';

my $META = Evo::Class::Meta->register(__PACKAGE__);

Evo::Internal::Util::monkey_patch __PACKAGE__, new => $META->attrs->gen_new;

1;
