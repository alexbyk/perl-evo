package main;
use Evo;
use Test::More;

{

  package Dest;
  use FindBin;
  use lib "$FindBin::Bin";
  use Evo '
    MyAttrFoo MODIFY_CODE_ATTRIBUTES;
    MyAttrBar MODIFY_CODE_ATTRIBUTES
  ';
  use Evo '
    MyAttrFoo MODIFY_CODE_ATTRIBUTES;
    MyAttrBar MODIFY_CODE_ATTRIBUTES
  ';

  sub foo : Foo : Bar {
  }

};

is Evo::Attr::Class::DEFAULT->handlers->{Dest}->@*, 2;

is_deeply $Dest::GOT_FOO , ['Dest', \&Dest::foo, qw(Foo Bar)];
is_deeply $Dest::GOT_BAR , ['Dest', \&Dest::foo, 'Bar'];


done_testing;
