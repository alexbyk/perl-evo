package main;
use Evo '-Export';
use Test::More;
sub EXPORTER {Evo::Export::Class::DEFAULT}

my $code = sub { };

*HANDLER = *Evo::Export::_attr_handler;

my @bad = HANDLER('Foo', $code, 'Bad', 'Export(name122)', 'Export(name2222)', 'Bad2()');
is_deeply \@bad, ['Bad', 'Bad2()'];

# anons
ok !HANDLER('Foo', $code, 'Export(name1)', 'Export(name2)');
is EXPORTER->request_gen('Foo', 'name1', 'Bar'), $code;
is EXPORTER->request_gen('Foo', 'name1', 'Bar'), $code;

# subs, 2 aliases, both should be exported
no warnings 'once';
local *Bar::mysub1 = $code;
local *Bar::mysub2 = $code;
HANDLER('Bar', $code, 'Export');
is EXPORTER->request_gen('Bar', 'mysub1', 'Dst'), $code;
is EXPORTER->request_gen('Bar', 'mysub2', 'Dst'), $code;

done_testing;
