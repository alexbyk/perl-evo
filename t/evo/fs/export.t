use Evo 'Test::More';

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs;
Evo::Fs->import('FS');

my %map = Evo::Fs->META->public_methods;
ok !$map{FS};
ok FS();
is FS(), FS();


done_testing;
