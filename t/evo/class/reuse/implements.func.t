package main;
use Evo 'Test::More';

{

  package My::Parent;
  use Evo '-Class; -Loaded';

  has myattr => 'a';
  sub mymeth {'A'}
  requires 'myreq';

  package My::Role;
  use Evo '-Class::Role; -Loaded';
  requires 'myrolereq';

  package My::ChildBad;
  use Evo '-Class; Test::More; Test::Fatal';
  like exception { implements 'My::Parent'; }, qr/myattr/;
  like exception { implements 'My::Role'; },   qr/myrolereq/;
  like exception { with 'My::Parent'; },       qr/myreq/;


  package My::Child;
  use Evo '-Class; Test::More';
  sub myattr    { }
  sub mymeth    { }
  sub myreq     { }
  sub myrolereq { }

  ok eval { implements qw(My::Role My::Parent ); 1 };

  package My::Child2;
  use Evo '-Class; Test::More';
  sub myreq     { }
  sub myrolereq { }

  ok eval { with qw(My::Role My::Parent ); 1 };

}


done_testing;
