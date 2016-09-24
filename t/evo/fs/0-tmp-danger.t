use Evo 'Test::More';
use Evo 'File::Spec::Functions catdir splitpath';

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs::Temp;

my $root;
FOO: {
  my $fs = Evo::Fs::Temp->new();
  $root = "" . $fs->root;
  BAIL_OUT "Bad Fs::Temp" unless ok $fs->path2real('/foo.txt') eq catdir($root, 'foo.txt');
  BAIL_OUT "Bad Fs::Temp"
    unless ok $fs->path2real('foo.txt') eq
    catdir($root, @{[splitpath($fs->cwd)]}[1, 2], 'foo.txt');
}

BAIL_OUT "Bad Fs::Temp" unless ok !-e $root;

done_testing;
