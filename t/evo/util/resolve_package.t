package main;
use Evo -Util;
use Test::More;
use Test::Fatal;

sub resolve { Evo::Util::resolve_package('My::Caller', @_) }

# full
is resolve('Foo'),      'Foo';
is resolve('Foo::Bar'), 'Foo::Bar';

# -
is resolve('-Foo'),      'Evo::Foo';
is resolve('-Foo::Bar'), 'Evo::Foo::Bar';

# :
is resolve(':Foo'),      'My::Caller::Foo';
is resolve(':Foo::Bar'), 'My::Caller::Foo::Bar';

# ::
is resolve('::Foo'),      'My::Foo';
is resolve('::Foo::Bar'), 'My::Foo::Bar';

like exception { resolve('!Foo') },   qr/Can't resolve.+\!Foo/i;
like exception { resolve('Foo!') },   qr/Can't resolve.+Foo\!/i;
like exception { resolve('--Foo') },  qr/Can't resolve.+--Foo/i;
like exception { resolve(':::Foo') }, qr/Can't resolve.+:::Foo/i;

# package can't start with 3, so Main, ::3 isn't good idea
like exception { Evo::Util::resolve_package('My', '::3') }, qr/Can't resolve.+::3.+My/i;

done_testing;
