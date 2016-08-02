use Evo 'Test::More; Evo::Internal::Exception; -Fs::Temp';
use Evo 'File::Spec; File::Temp';
use File::Basename 'fileparse';

# traverse
foreach my $fs (Evo::Fs::Temp->new(), Evo::Fs->new(cwd => File::Temp->newdir)) {
  $fs->write_many(
    'f.txt' => 'txt',
    File::Spec->catdir($fs->cwd, "a/1/f.txt") => 'foo',
    'a/2/f.txt'                => 'bar',
    'b/1/f.txt'                => 'bar',
    'skip_further/bad/bad.txt' => 'bar',
    'skip_further/bad.txt'     => 'bar',
  );

  my (@children, @dirs);
  $fs->traverse(
    './',
    sub ($path, $stat) {
      push @children, $path;
    },
    sub ($path, $stat) {
      push @dirs, $path;
      scalar fileparse($path) ne 'skip_further';
    },
  );


  my @rel_children = sort map { File::Spec->abs2rel($_,       $fs->cwd) } @children;
  my @rel_dirs     = sort map { File::Spec->abs2rel($_, $fs->cwd) } @dirs;

  # see skip once only
  is_deeply \@rel_dirs, [sort qw(a a/1 a/2 b b/1 skip_further)];

  is_deeply \@rel_children, [
    sort qw(
      f.txt
      a b skip_further
      a/1 a/2 b/1
      a/1/f.txt a/2/f.txt b/1/f.txt
      )
  ];

}

# order
foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
  $fs->write_many('a/1/f.txt' => 'bar', 'b/1/f.txt' => 'bar', 'c/1/2/f.txt' => 'bar');

  my @children;
  $fs->traverse(
    './',
    sub ($f, $stat) {
      push @children, $f;
    },
  );

  my @rel_children = sort map { File::Spec->abs2rel($_, $fs->cwd) } @children;
  is_deeply \@rel_children, [
    sort qw(
      a a/1 a/1/f.txt
      b b/1 b/1/f.txt
      c c/1 c/1/2 c/1/2/f.txt
      )
  ];
}

# many sources
foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
  $fs->write_many('a/1/f.txt' => 'bar', 'b/1/f.txt' => 'bar');

  my @children;
  $fs->traverse(
    ['a', 'b'],
    sub ($f, $stat) {
      push @children, $f;
    },
  );

  my @rel_children = sort map { File::Spec->abs2rel($_, $fs->cwd) } @children;
  is_deeply \@rel_children, [sort qw( a/1 a/1/f.txt b/1 b/1/f.txt)];
}

# circular
foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
  $fs->write('a/1/f.txt' => 'foo');
  $fs->symlink('a',         'a/1/a.slnk');
  $fs->symlink('a/1/f.txt', 'a/1/f.slnk');
  $fs->link('a/1/f.txt', 'a/1/f.hlnk');

  my (@children, @dirs);
  $fs->traverse(
    ['./', './', 'a/'],
    sub ($f, $stat) {
      push @children, $f;
    },
    sub ($d, $stat) {
      push @dirs, $d;
    },
  );


  my @rel_children = sort map { File::Spec->abs2rel($_,       $fs->cwd) } @children;
  my @rel_dirs     = sort map { File::Spec->abs2rel($_, $fs->cwd) } @dirs;

  is_deeply \@rel_children, [sort qw(a a/1 a/1/a.slnk a/1/f.slnk a/1/f.hlnk a/1/f.txt)],;
}

# skip dir can't read
foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
  $fs->mkdir('bad1', oct 100);
  $fs->mkdir('bad2', oct 400);
  $fs->mkdir('bad3', oct 600);
  $fs->write("good/f", oct 500);

  my (@children, @dirs);
  $fs->traverse(
    './',
    sub ($path, $stat) {
      push @children, $path;
    },
    sub ($d, $stat) {
      push @dirs, $d;
      1;
    },
  );


  my @rel_children = sort map { File::Spec->abs2rel($_,       $fs->cwd) } @children;
  my @rel_dirs     = sort map { File::Spec->abs2rel($_, $fs->cwd) } @dirs;

  # see skip once only
  is_deeply \@rel_dirs,     [sort qw(good)];
  is_deeply \@rel_children, [sort qw(bad1 bad2 bad3 good good/f)];

}


# files
foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
  $fs->write_many(
    'f.txt'                => 'txt',
    'a/1/f.txt'            => 'bar',
    'b/1/f.txt'            => 'bar',
    'skip_further/bad.txt' => 'bar',
  );
  $fs->make_tree('links');

  $fs->symlink('f.txt', 'links/f.slnk');
  $fs->link('f.txt', 'links/f.hlnk');

  my (@files, @dirs);
  $fs->find_files(
    '.',
    sub ($path, $stat) {
      push @files, $path;
    },
    sub ($path, @) {
      push @dirs, $path;
      scalar fileparse($path) ne 'skip_further';
    },
  );

  my @rel_files = sort map { File::Spec->abs2rel($_, $fs->cwd) } @files;
  my @rel_dirs  = sort map { File::Spec->abs2rel($_, $fs->cwd) } @dirs;

  $, = '; ';
  is_deeply \@rel_dirs,  [sort qw(a a/1 b b/1 links skip_further)];
  is_deeply \@rel_files, [sort qw( f.txt a/1/f.txt b/1/f.txt)];

}


done_testing;
