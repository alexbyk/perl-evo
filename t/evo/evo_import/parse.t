use Evo;
use Test::More;
use Test::Fatal;

sub parse { [Evo::_parse('My::Caller', @_)] }
sub parse_from { [Evo::_parse(@_)] }


is_deeply parse('Foo'),      ['Foo'];
is_deeply parse('Foo::Bar'), ['Foo::Bar'];

is_deeply parse('Foo(bar baz)'),       [qw(Foo bar baz)];
is_deeply parse('Foo::Bar (bar baz)'), [qw(Foo::Bar bar baz)];
is_deeply parse('Foo(bar,baz)'),       [qw(Foo  bar baz)];
is_deeply parse('Foo (bar,baz)'),      [qw(Foo  bar baz)];
is_deeply parse('Foo (bar baz)'),      [qw(Foo  bar baz)];
is_deeply parse('Foo [bar baz]'),      [qw(Foo  bar baz)];

is_deeply parse('Foo(:all)'), [qw(Foo  :all)];

is_deeply parse('Foo bar baz'), [qw(Foo  bar baz)];
is_deeply parse('Foo bar,baz'), [qw(Foo  bar baz)];

is_deeply parse('-Foo'),         [qw(Evo::Foo )];
is_deeply parse('-Foo bar baz'), [qw(Evo::Foo  bar baz)];
is_deeply parse('-33 bar baz'),  [qw(Evo::33  bar baz)];

is_deeply parse('-Foo [bar baz]'),  [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo (bar, baz)'), [qw(Evo::Foo  bar baz)];

is_deeply parse('-Foo[bar baz]'),  [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo[bar, baz]'), [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo[bar, baz]'), [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo[bar,baz]'),  [qw(Evo::Foo  bar baz)];

is_deeply parse('-Foo(bar baz)'),  [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo(bar, baz)'), [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo(bar, baz)'), [qw(Evo::Foo  bar baz)];
is_deeply parse('-Foo(bar,baz)'),  [qw(Evo::Foo  bar baz)];

is_deeply parse('-Foo ()'), [qw(Evo::Foo)];
is_deeply parse('-Foo []'), [qw(Evo::Foo)];

# new lines
is_deeply parse("Foo \nbar\n\nbaz"), [qw(Foo  bar baz)];

# trim
is_deeply parse(' My::Foo '),         [qw(My::Foo)];
is_deeply parse(' My::Foo bar baz '), [qw(My::Foo bar baz)];

# :: => parent
is_deeply parse_from('main',    '::Foo'),             [qw(Foo)];
is_deeply parse_from('My::Foo', '::Bar::Baz'),        [qw(My::Bar::Baz)];
is_deeply parse_from('My::Foo', '::Bar hello there'), [qw(My::Bar hello there)];
is_deeply parse_from('My::Foo', ':: hello there'),    [qw(My hello there)];
is_deeply parse_from('My::Foo', '::33 hello there'),  [qw(My::33 hello there)];

# : => current
is_deeply parse_from('My::Foo', ':Bar::Baz'),        [qw(My::Foo::Bar::Baz)];
is_deeply parse_from('My::Foo', ':Bar hello there'), [qw(My::Foo::Bar hello there)];
is_deeply parse_from('My::Foo', ':33 hello there'),  [qw(My::Foo::33 hello there)];

done_testing;
