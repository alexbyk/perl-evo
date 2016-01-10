package main;
use Evo '-Export MODIFY_CODE_ATTRIBUTES', '-Export EXPORTER';
use Test::More;

my $code = sub { };

my @bad = MODIFY_CODE_ATTRIBUTES('Foo', $code, 'Bad', 'Export(name1)', 'Export(name2)', 'Bad2()');
is_deeply \@bad, ['Bad', 'Bad2()'];

# anons
ok !MODIFY_CODE_ATTRIBUTES('Foo', $code, 'Export(name1)', 'Export(name2)');
is EXPORTER->request_gen('Foo', 'name1', 'Bar'), $code;
is EXPORTER->request_gen('Foo', 'name1', 'Bar'), $code;

# subs, 2 aliases, both should be exported
no warnings 'once';
local *Bar::mysub1 = $code;
local *Bar::mysub2 = $code;
MODIFY_CODE_ATTRIBUTES('Bar', $code, 'Export');
is EXPORTER->request_gen('Bar', 'mysub1', 'Dst'), $code;
is EXPORTER->request_gen('Bar', 'mysub2', 'Dst'), $code;

done_testing;
