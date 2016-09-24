use Evo 'Test::More; Evo::Internal::Exception';
use Evo 'File::Spec; File::Spec::Functions rel2abs abs2rel; File::Temp';
use File::Basename 'fileparse';

plan skip_all => "Win isn't supported yet" if $^O eq 'MSWin32';
require Evo::Fs::Temp;

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
    sub ($path) {
      push @children, $path;
    },
    sub ($path) {
      push @dirs, $path;
      scalar fileparse($path) ne 'skip_further';
    },
  );

  @dirs     = map { File::Spec->canonpath($_) } sort @dirs;
  @children = map { File::Spec->canonpath($_) } sort @children;

  # see skip once only
  is_deeply \@dirs, [map { abs2rel rel2abs($_) } sort qw(a a/1 a/2 b b/1 skip_further)];
  is_deeply \@children, [
    map { abs2rel rel2abs($_) }
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
    sub ($f) {
      push @children, $f;
    },
  );

  @children = map { File::Spec->canonpath($_) } sort @children;
  is_deeply \@children, [
    map { abs2rel rel2abs($_) }
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
  $fs->traverse(['a', 'b'], sub ($f) { push @children, $f; },);

  @children = map { File::Spec->canonpath($_) } sort @children;
  is_deeply \@children, [sort map { abs2rel rel2abs($_) } qw( a/1 a/1/f.txt b/1 b/1/f.txt)];
}

CIRC: {
  foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
    $fs->write('a/1/f.txt' => 'foo');

    $fs->symlink('a',         'a/1/a.slnk');
    $fs->symlink('a/1/f.txt', 'a/1/f.txt.slnk');
    $fs->link('a/1/f.txt', 'a/1/f.txt.hlnk');

    my (@children, @dirs);
    $fs->traverse(['./', './', 'a/'], sub ($f) { push @children, $f; });


    @children = map { File::Spec->canonpath($_) } sort @children;
    is_deeply \@children, [sort qw(a a/1 a/1/f.txt)],;
  }
}

SKIP: {
  foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
    $fs->mkdir('bad1', oct 100);
    $fs->mkdir('bad2', oct 400);
    $fs->mkdir('bad3', oct 600);
    $fs->write("good/f", oct 500);

    my (@children, @dirs);
    $fs->traverse(
      './',
      sub ($path) {
        push @children, $path;
      },
      sub ($d) {
        push @dirs, $d;
        1;
      },
    );


    @dirs     = map { File::Spec->canonpath($_) } sort @dirs;
    @children = map { File::Spec->canonpath($_) } sort @children;

    # see skip once only
    is_deeply \@dirs,     [sort qw(good)];
    is_deeply \@children, [sort qw(bad1 bad2 bad3 good good/f)];

  }
}


# files
FILES: {

  foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
    $fs->write_many(
      'f.txt'                => 'txt',
      'a/1/f.txt'            => 'bar',
      'b/1/f.txt'            => 'bar',
      'skip_further/bad.txt' => 'bar',
    );

    my (@files, @dirs);
    $fs->find_files(
      '.',
      sub ($path) {
        push @files, $path;
      },
      sub ($path) {
        push @dirs, $path;
        scalar fileparse($path) ne 'skip_further';
      },
    );

    @dirs  = map { File::Spec->canonpath($_) } sort @dirs;
    @files = map { File::Spec->canonpath($_) } sort @files;

    is_deeply \@dirs,  [sort qw(a a/1 b b/1 skip_further)];
    is_deeply \@files, [sort qw( f.txt a/1/f.txt b/1/f.txt)];
  }

}


FILES_LINKS: {
  foreach my $fs (Evo::Fs->new(cwd => File::Temp->newdir), Evo::Fs::Temp->new()) {
    $fs->write_many('f.txt' => 'txt',);
    $fs->make_tree('links');

    $fs->symlink('f.txt', 'links/f.slnk');
    $fs->symlink('404',   'links/bad.slnk');
    $fs->link('f.txt', 'links/f.hlnk');

    my (@files, @dirs);
    $fs->find_files('.', sub ($path) { push @files, $path; });
    @files = map { File::Spec->canonpath($_) } sort @files;

    is_deeply \@files, ['f.txt'];

  }
}

done_testing;
