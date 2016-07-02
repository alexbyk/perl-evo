use Evo '-Export; -Internal::Util';
use Test::More;

*HANDLER = *Evo::Export::MODIFY_CODE_ATTRIBUTES;
my $code = sub { };
my $gen  = sub {$code};


my @bad = HANDLER('My::Foo', $code, 'Bad', 'Export', 'Export(name2222)', 'Bad2()');
ok my $meta = Evo::Internal::Util::pkg_stash('My::Foo', 'Evo::Export::Meta');
is_deeply \@bad, ['Bad', 'Bad2()'];

@bad = HANDLER('My::Bar', $code, 'Bad', 'ExportGen', 'ExportGen(name)', 'Bad2()');
is_deeply \@bad, ['Bad', 'Bad2()'];

# anons
ok !HANDLER('My::Foo', $code, 'Export(name1)', 'Export(name2)');
is $meta->request('name1', 'main'), $code;
is $meta->request('name2', 'main'), $code;

ok !HANDLER('My::Foo', $gen, 'ExportGen(g1)', 'ExportGen(g2)');
is $meta->request('g1', 'main'), $code;
is $meta->request('g2', 'main'), $code;

done_testing;
