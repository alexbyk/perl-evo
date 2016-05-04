use Evo;
use Evo '-Class::Meta';
use Test::More;
use Test::Fatal;

no warnings 'once';
no warnings 'redefine';
local *Evo::Class::Meta::gen_check_ro = sub {"RO $_[0]"};

*process_is = *Evo::Class::Meta::process_is;


ATTR: {
  like exception { process_is('name', is => 'bad') }, qr/"is".+"bad".+$0/;

  my $res;
  $res = {process_is('name', check => 'bad', is => 'ro')};
  is_deeply $res, {check => 'RO name'};

  $res = {process_is('name', is => 'ro')};
  is_deeply $res, {check => 'RO name'};

}

done_testing;
