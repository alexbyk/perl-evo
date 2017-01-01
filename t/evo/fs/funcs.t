use Evo 'Test::More; -Fs SKIP_HIDDEN';

ok !SKIP_HIDDEN->('.git');
ok !SKIP_HIDDEN->('foo/.git');
ok !SKIP_HIDDEN->('/foo/.git');
ok SKIP_HIDDEN->('foo/foo.git');


done_testing;
