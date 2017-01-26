use Evo 'Test::More; -Fs SKIP_HIDDEN';
plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';

ok !SKIP_HIDDEN->('.git');
ok !SKIP_HIDDEN->('foo/.git');
ok !SKIP_HIDDEN->('/foo/.git');
ok SKIP_HIDDEN->('foo/foo.git');


done_testing;
