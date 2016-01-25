package main;
use Evo;
use Test::More;

{

  package My::Lib;
  use Evo '-Export *', -Loaded;

  sub foo {'FOO'}
  sub bar {'BAR'}

  BEGIN {
    export qw(foo bar);
  }
}

use Evo 'My::Lib * -foo foo:foo_renamed';
is foo_renamed(), 'FOO';
is bar(),         'BAR';
ok !main::->can('foo');

done_testing;
