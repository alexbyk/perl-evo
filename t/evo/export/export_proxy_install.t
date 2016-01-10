package main;
use Evo '-Export export_install_in';
use Test::More;
{

  package My::Lib;
  use Evo '-Export export export_gen export_anon', -Loaded;
  export('foo', 'foo:boo');
  sub foo {'FOO'}

  export_gen hello => sub {
    my $dst = shift;
    sub {"hello $dst"}
  };

  export_anon bye => sub {"bye"};

  package My::Proxy;
  use Evo '-Export export_proxy';
  export_proxy('My::Lib', 'foo:pfoo');
}

# fn
export_install_in('My::Dst', 'My::Lib', 'bye');
is My::Dst::bye(), 'bye';
ok !My::Lib->can('bye');

# gen
export_install_in('My::Dst', 'My::Lib', 'hello');
is My::Dst::hello(), 'hello My::Dst';

# simple
export_install_in('My::Dst', 'My::Lib', 'foo');
is My::Dst::foo(), 'FOO';

# renamed on export
export_install_in('My::Dst', 'My::Lib', 'boo');
is My::Dst::boo(), 'FOO';

# renamed
export_install_in('My::Dst', 'My::Lib', 'foo:foo_renamed');
is My::Dst::foo_renamed(), 'FOO';

# via proxy
export_install_in('My::Dst', 'My::Proxy', 'pfoo');
is My::Dst::pfoo(), 'FOO';

done_testing;
