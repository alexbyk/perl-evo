use Evo 'Test::More; Evo::Internal::Exception; -Fs::Class::Temp';
use Evo 'Fcntl; File::Spec';


my $fs = Evo::Fs::Class::Temp->new();

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

like exception { $fs->open('/foo', 'BAD'); }, qr/bad mode BAD/i;

OPEN_BY_FILE: {
  my $file = $fs->open('foo', 'w');
  $fs->syswrite($file, 'hello');
  ok $fs->sysopen($file, 'r'), $file;
  $fs->sysread($file, \my $buf, 100);
  is $buf, 'hello';
}


OPEN_RELATIVE_MAKES_FILE_WITH_ABS_PATH: {
  my $buf;
  _write('foo', 'hello');
  my $file = $fs->open('foo', 'r');
  ok(File::Spec->file_name_is_absolute($file->path));
  is $file->path, $fs->to_abs('foo');
  $fs->unlink('foo');
}


OPEN_R: {
  like exception { $fs->open('/foo', 'r') }, qr/No such file.+$0/;

  my $buf;
  _write('/foo', 'hello');
  my $file = $fs->open('/foo', 'r');
  $fs->sysread($file, \$buf, 100);
  is $buf, 'hello';

  local $SIG{__WARN__} = sub { };
  like exception { $fs->syswrite($file, 'hello') }, qr/Can't write.+$0/;
  $fs->unlink('/foo');

}

OPEN_R_PLUS: {
  like exception { $fs->open('/foo', 'r+') }, qr/No such file.+$0/;

  my $buf;
  _write('/foo', 'hello');
  my $file = $fs->open('/foo', 'r+');
  $fs->syswrite($file, "12");
  $fs->sysseek($file, 0);
  $fs->sysread($file, \$buf, 100);
  is $buf, '12llo';

  $fs->unlink('/foo');
}

OPEN_W: {
  my $mode = 'w';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  is _slurp('/foo'), 'hello';

  # truncate
  $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, '12');
  is _slurp('/foo'), '12';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($file, \my $buf, 100) }, qr/Can't read.+$0/;

  $fs->unlink('/foo');
}

OPEN_WX: {
  my $mode = 'wx';
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  is _slurp('/foo'), 'hello';

  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($file, \my $buf, 100) }, qr/Can't read.+$0/;

  # exists
  like exception { $fs->open('/foo', $mode) }, qr/File exists.+$0/;
  $fs->unlink('/foo');
}

OPEN_W_PLUS: {
  my $buf;
  my $mode = 'w+';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  $fs->sysseek($file, 0);
  $fs->sysread($file, \$buf, 100);
  is $buf, 'hello';

  # truncate
  $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, '12');
  is _slurp('/foo'), '12';

  $fs->unlink('/foo');
}

OPEN_WX_PLUS: {
  my $buf;
  my $mode = 'wx+';

  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  $fs->sysseek($file, 0);
  $fs->sysread($file, \$buf, 100);
  is $buf, 'hello';

  # exists
  like exception { $fs->open('/foo', $mode) }, qr/File exists.+$0/;
  $fs->unlink('/foo');
}


A: {

  my $mode = 'a';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  is _slurp('/foo'), 'hello';

  # reopen append
  $file = $fs->open('/foo', $mode);
  $fs->sysseek($file, 0);    # ignored
  $fs->syswrite($file, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($file, \my $buf, 100) }, qr/Can't read.+$0/;

  $fs->unlink('/foo');
}

AX: {
  my $mode = 'ax';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  $fs->sysseek($file, 0);    # ignored
  $fs->syswrite($file, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # not for read
  local $SIG{__WARN__} = sub { };
  like exception { $fs->sysread($file, \my $buf, 100) }, qr/Can't read.+$0/;

  # exists
  like exception { $fs->open('/foo', $mode) }, qr/File exists.+$0/;
  $fs->unlink('/foo');
}


A_PLUS: {
  my $buf;
  my $mode = 'a+';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');

  # reopen append
  $file = $fs->open('/foo', $mode);
  $fs->sysseek($file, 0);    # ignored
  $fs->syswrite($file, 'foo');
  is _slurp('/foo'), 'hellofoo';

  # read
  $fs->sysseek($file, 0);
  $fs->sysread($file, \$buf, 100);
  is $buf, 'hellofoo';

  $fs->unlink('/foo');
}

AX_PLUS: {

  my $buf;
  my $mode = 'ax+';

  # create
  my $file = $fs->open('/foo', $mode);
  $fs->syswrite($file, 'hello');
  $fs->sysseek($file, 0);    # ignored
  $fs->syswrite($file, 'foo');
  is _slurp('/foo'), 'hellofoo';

  $fs->sysseek($file, 0);
  $fs->sysread($file, \$buf, 100);
  is $buf, 'hellofoo';

  # exists
  like exception { $fs->open('/foo', $mode) }, qr/File exists.+$0/;
  $fs->unlink('/foo');
}

done_testing;
