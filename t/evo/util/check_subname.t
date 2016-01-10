use Evo -Util;
use Test::More;

ok Evo::Util::check_subname("Fo_3oad");
ok Evo::Util::check_subname("f");
ok !Evo::Util::check_subname(" Foo");
ok !Evo::Util::check_subname("3Foo");
ok !Evo::Util::check_subname("foo-Foo");
ok !Evo::Util::check_subname("foo:Foo");

done_testing;

