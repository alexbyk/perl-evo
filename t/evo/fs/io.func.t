use Evo 'Test::More; Evo::Internal::Exception; -Fs::Class::Temp';
use Evo 'Fcntl; Time::HiRes time';

my $fs = Evo::Fs::Class::Temp->new();

ok $fs->stat($fs->cwd)->is_dir;

sub _write ($path, $what) {
  my $file = $fs->open($path, 'w');
  $fs->syswrite($file, $what);
  $fs->close($file);
}

sub _slurp ($path) {
  my $file = $fs->open($path, 'r');
  my $buf;
  $fs->sysread($file, \$buf, 100);
  $fs->close($file);
  $buf;
}

diag "Testing " . ref $fs;

EXISTS_SIZE: {
  ok !$fs->exists('/foo');
  _write('/foo', '123');
  ok $fs->stat('/foo')->is_file;
  $fs->unlink('/foo');
  ok !$fs->exists('/foo');
}

# maybe superfluous
#SYSOPEN_CLOSE: {
#  my $file = $fs->sysopen('/foo', O_WRONLY | O_CREAT);
#  $fs->syswrite($file, "123456");
#  $fs->close($file);
#  is _slurp('/foo'), '123456';
#
#  $file = $fs->sysopen('/foo', O_WRONLY | O_CREAT);
#  $fs->syswrite($file, "xxx");
#  $fs->close($file);
#  is _slurp('/foo'), 'xxx456';
#
#  $file = $fs->sysopen('/foo', O_WRONLY | O_CREAT | O_TRUNC);
#  $fs->syswrite($file, "new");
#  $fs->close($file);
#  is _slurp('/foo'), 'new';
#
#  $fs->unlink('/foo');
#}

READ: {
  _write('/foo', '123456');

  my $file = $fs->open('/foo', 'r');
  my $buf = 'xxBAD';
  $fs->sysread($file, \$buf, 3, 2);
  is $buf, 'xx123';

  $buf = '';
  $fs->sysread($file, \$buf, 2);
  is $buf, '45';

  # read many
  $fs->unlink('/foo');
  _write('/foo', '123456');
  $file = $fs->open('/foo', 'r');
  is $fs->sysread($file, \$buf, 1000), 6;

  $fs->unlink('/foo');
}

SEEK: {
  # sysseek
  _write('/foo', '123456');

  my $file = $fs->open('/foo', 'r');

  like exception { $fs->sysseek($file, 10, 'BAD') }, qr/bad.+BAD.+$0/i;
  my $buf = '';
  $fs->sysread($file, \$buf, 100);    # to end
  $fs->sysseek($file, 0);
  $buf = '';
  $fs->sysread($file, \$buf, 100);
  is $buf, '123456';


  $buf = '';
  $fs->sysseek($file, -3, 'cur');
  $fs->sysread($file, \$buf, 100);
  is $buf, '456';

  $buf = '';
  $fs->sysseek($file, -2, 'end');
  $fs->sysread($file, \$buf, 100);
  is $buf, '56';

  $fs->unlink('/foo');
}


# different forms of read
# different forms of write
WRITE: {
  my $file = $fs->open('/foo', 'w');
  is $fs->syswrite($file, "123456"), 6;
  is _slurp('/foo'), '123456';
  $fs->unlink('/foo');

  $file = $fs->open('/foo', 'w');
  is $fs->syswrite($file, "123456", 2), 2;
  is _slurp('/foo'), '12';
  $fs->unlink('/foo');

  $file = $fs->open('/foo', 'w');
  is $fs->syswrite($file, "123456", 3, 1), 3;
  is _slurp('/foo'), '234';
  $fs->unlink('/foo');

  $file = $fs->open('/foo', 'w');
  is $fs->syswrite($file, "123456", 1000), 6;
  is _slurp('/foo'), '123456';
  $fs->unlink('/foo');
}


STAT: {
  $fs->write("/foo", 'hello');
  my $stat = $fs->stat('/foo');
  ok $stat->dev;
  is $stat->size, 5;
  ok $stat->is_file;
  ok !$stat->is_dir;
  $fs->unlink('/foo');

  $fs->mkdir('/somedir');
  $stat = $fs->stat('/somedir');
  ok $stat->dev;
  ok !$stat->is_file;
  ok $stat->is_dir;
  $fs->remove_tree('/somedir');

  # cando
  $fs->open("/foo", 'w', oct 000);
  $stat = $fs->stat('/foo');
  ok !$stat->can_read;
  ok !$stat->can_write;
  ok !$stat->can_exec;
  is $stat->perms, oct 000;
  $fs->unlink('/foo');

  $fs->open("/foo", 'w', oct 700);
  $stat = $fs->stat('/foo');
  ok $stat->can_read;
  ok $stat->can_write;
  ok $stat->can_exec;
  is $stat->perms, oct 700;
  $fs->unlink('/foo');
}

UTIMES: {
  _write('/foo', 'hello');
  $fs->utimes('/foo', 1, 2);
  my $stat = $fs->stat('/foo');
  is $stat->atime, 1;
  is $stat->mtime, 2;
}

LOCK: {
  _write('/foo', 'hello');
  my $file1 = $fs->open('/foo', 'r');
  my $file2 = $fs->open('/foo', 'r');
  my $file3 = $fs->open('/foo', 'r+');
  my $file4 = $fs->open('/foo', 'r+');

  ok $fs->flock($file1, 'sh');
  ok $fs->flock($file2, 'sh');

  ok !$fs->flock($file3, 'ex_nb');

  ok $fs->flock($file1, 'un');
  ok $fs->flock($file2, 'un');

  ok $fs->flock($file3, 'ex_nb');
  $fs->unlink('/foo');
}

SYMLINK: {
  $fs->write('/foo', 'foo');
  $fs->symlink('/foo', '/link');
  is $fs->read('/link'), 'foo';
  is $fs->stat('/foo')->ino, $fs->stat('/link')->ino;
  ok $fs->is_symlink('/link');
  ok !$fs->is_symlink('/foo');

  like exception { $fs->symlink('/404', '/link') }, qr/exists.+$0/;
  $fs->unlink('/foo');
  $fs->unlink('/link');
}

LINK: {
  $fs->write('/foo', 'foo');
  $fs->link('/foo', '/link');
  is $fs->read('/link'), 'foo';
  is $fs->stat('/foo')->ino, $fs->stat('/link')->ino;
  ok !$fs->is_symlink('/link');
  ok !$fs->is_symlink('/foo');

  like exception { $fs->symlink('/404', '/link') }, qr/exists.+$0/;
  $fs->unlink('/foo');
  is $fs->read('/link'), 'foo';
  $fs->unlink('/link');
}

RENAME: {
  $fs->write('/foo', 'foo');
  $fs->rename('/foo', '/bar');
  ok !$fs->exists('/foo');
  is $fs->read('/bar'), 'foo';
  $fs->unlink('/bar');
}


# ---------- dirs
MAKE_TREE: {
  $fs->make_tree('/bar/p2/p3');
  ok $fs->stat('/bar/p2/p3')->is_dir;
  $fs->remove_tree('/bar');

  $fs->make_tree('/bar/p2/p3', oct 700);
  is $fs->stat('/bar/p2/p3')->perms, oct 700;

  $fs->remove_tree('/bar');
}


MKDIR: {
  ok !$fs->exists('/bar');
  $fs->mkdir('/bar');
  ok $fs->stat('/bar')->is_dir;
  $fs->remove_tree('/bar');

  $fs->mkdir('/bar', oct 700);
  is $fs->stat('/bar')->perms, oct 700;
  $fs->remove_tree('/bar');
}

# list
$fs->mkdir('/bar');
$fs->open('/bar/f1', 'w');
$fs->open('/bar/f2', 'w');
is_deeply [sort $fs->ls('/bar')], [qw(f1 f2)];

$fs->remove_tree('/bar');
ok !$fs->exists('/bar');

ERRORS: {
  # exceptions file
  local $SIG{__WARN__} = sub { };
  _write('/existing', 'foo');
  my $file = $fs->open('/existing', 'r');

  # flock
  $file = $fs->open('/existing', 'r');
  like exception { $fs->flock($file, 'boo') }, qr/flag.+$0/i;

  $file = $fs->open('/existing', 'r');
  $fs->close($file);
  like exception { $fs->flock($file, 'sh') }, qr/bad.+descriptor.+$0/i;

  # utimes
  like exception { $fs->utimes('/not_exists', undef, undef); }, qr/No such.+$0/;


  $fs->mkdir('/existing_dir');
  like exception { $fs->open('/existing_dir', 'w'); }, qr/is a directory.+$0/i;
  like exception { $fs->unlink('/not_exists'); }, qr/No such file.+$0/;
  like exception { $fs->stat('/not_exists'); },   qr/No such file or directory.+$0/;

  # exceptions dir
  like exception { $fs->remove_tree('/not_exists'); }, qr/No such.+directory.+$0/;
  like exception { $fs->ls('/not_exists'); },          qr/No such.+directory.+$0/;

  _write('/not_a_dir', 'foo');
  like exception { $fs->make_tree('/not_a_dir'); }, qr/exists.+$0/i;
  like exception { $fs->mkdir('/not_a_dir') }, qr/exists.+$0/i;
  like exception { $fs->mkdir('/mydir') for 1 .. 2; }, qr/exists.+$0/i;
}

done_testing;
