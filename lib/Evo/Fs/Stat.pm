package Evo::Fs::Stat;
use Evo -Class, 'Fcntl :mode';
use File::stat();

has 'dev';
has 'ino';
has 'mode';
has 'nlink';
has 'uid';
has 'gid';
has 'rdev';
has 'size';
has 'atime';
has 'mtime';
has 'ctime';
has 'blksize';
has 'blocks';
has '_data';

sub is_file($self) { S_ISREG($self->mode) }
sub is_dir($self)  { S_ISDIR($self->mode) }


sub can_read($self) {
  File::stat::stat_cando($self->_data, S_IRUSR);
}

sub can_write($self) {
  File::stat::stat_cando($self->_data, S_IWUSR);
}

sub can_exec($self) {
  File::stat::stat_cando($self->_data, S_IXUSR);
}

sub perms($self) { $self->mode & oct(7777) }

1;
