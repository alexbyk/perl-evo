use Evo -Lib::Bare;
use Test::More;

ok Evo::Lib::Bare::check_subname("Fo_3oad");
ok Evo::Lib::Bare::check_subname("f");
ok !Evo::Lib::Bare::check_subname(" Foo");
ok !Evo::Lib::Bare::check_subname("3Foo");
ok !Evo::Lib::Bare::check_subname("foo-Foo");
ok !Evo::Lib::Bare::check_subname("foo:Foo");

done_testing;

