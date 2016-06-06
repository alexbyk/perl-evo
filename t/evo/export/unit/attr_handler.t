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


done_testing;
