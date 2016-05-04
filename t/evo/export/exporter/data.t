use Evo -Export::Class;
use Test::More;
use Test::Fatal;

my $loaded;
no warnings 'redefine';    ## no critic
local *Evo::Export::Class::load = sub { $loaded = shift };

CREATE: {
  my $obj = Evo::Export::Class::new();
  ok $obj->data;
}

GEN: {
  my $obj = Evo::Export::Class::new();
  $obj->add_gen(src => name => 'GEN');
  is $obj->data->{src}{name}{gen}, 'GEN';

  like exception { $obj->add_gen(src => name => 'GEN'); }, qr/src.+name.+$0/;
}


PROXY: {
  my $obj = Evo::Export::Class::new();

  like exception { $obj->add_proxy('epkg', 'ename', 'spkg', 'sname') }, qr/spkg.+sname.+$0/;

  $obj->add_gen(spkg => sname => 'GEN');

  $obj->add_proxy('epkg', 'ename', 'spkg', 'sname');
  use Data::Dumper;
  is_deeply $obj->data->{epkg}{ename}, {gen => 'GEN'};
  like exception { $obj->add_proxy('epkg', 'ename', 'spkg', 'sname') }, qr/epkg.+ename.+$0/;
}


SUB: {
  my $obj = Evo::Export::Class::new();
  like exception { $obj->add_sub('My::Src', 'name') },     qr/My::Src::name.+$0/;
  like exception { $obj->add_sub('My::Src', 'name:fee') }, qr/My::Src::name.+$0/;

  no warnings 'once';
  local *My::Src::name = my $sub = sub { };
  $obj->add_sub('My::Src', 'name');
  $obj->add_sub('My::Src', 'name:alias');
  is $obj->data->{'My::Src'}{name}{gen}->(),  $sub;
  is $obj->data->{'My::Src'}{alias}{gen}->(), $sub;
}


REEXPORT_ALL: {
  my $obj = Evo::Export::Class::new();
  $obj->add_gen('Evo::My::Lib', 'name1', 'gen1');
  $obj->add_gen('Evo::My::Lib', 'name2', 'gen2');

  $obj->proxy('Proxy', '-My::Lib', '*');
  is_deeply $obj->data->{Proxy}, {name1 => {gen => 'gen1'}, name2 => {gen => 'gen2'},};

  is $loaded, 'Evo::My::Lib';
}

REEXPORT_SEVERAL_AS: {
  my $obj = Evo::Export::Class::new();
  $obj->add_gen('Lib', 'name1', 'gen1');

  $obj->proxy('Proxy', 'Lib', 'name1:renamed1');
  is_deeply $obj->data->{Proxy}, {renamed1 => {gen => 'gen1'}};
}

done_testing;
