use Evo 'Test::More; Evo::Internal::Exception; -Fs::Class::Temp';
use Evo 'Fcntl';


RWA: {

  my $fs = Evo::Fs::Class::Temp->new();
  my $called;
  no warnings 'redefine';
  local *Evo::Fs::Class::Temp::flock = sub { $called++ };

  isa_ok $fs->write('/a/foo', 'bad'), 'Evo::Fs::File';
  $fs->write('/a/foo', 'hello');
  isa_ok $fs->append('/a/foo', 'bar'), 'Evo::Fs::File';
  $fs->append('/b/foo', 'bbb');
  is $fs->read('/a/foo'), 'hellobar';
  is $fs->read('/b/foo'), 'bbb';
  is $called, 12;
}

RWA_FILE: {
  my $fs   = Evo::Fs::Class::Temp->new();
  my $file = $fs->file('/a/foo');
  $fs->write($file, 'bad');
  $fs->write($file, 'hello');
  $fs->append($file, 'bar');
  is $fs->read($file), 'hellobar';
}

WRITE_MANY: {
  my $fs  = Evo::Fs::Class::Temp->new();
  my $bar = $fs->file('bar');
  $fs->write_many('/a/foo' => 'afoo', '/b/foo' => 'bfoo', 'bar' => 'bar');
  is $fs->read('/a/foo'), 'afoo';
  is $fs->read('/b/foo'), 'bfoo';
  is $fs->read('bar'),    'bar';
}

done_testing;
