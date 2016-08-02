use Evo 'Test::More; -Fs *';

my %map = Evo::Fs->META->public_methods;
ok !$map{FS};
ok FS();
is FS(), FS();


done_testing;
