package Evo::Fs::Stat;
use Evo -Class, 'Fcntl :mode';
use File::stat();

has 'dev',     required => 1, is => 'ro';
has 'ino',     required => 1, is => 'ro';
has 'mode',    required => 1, is => 'ro';
has 'nlink',   required => 1, is => 'ro';
has 'uid',     required => 1, is => 'ro';
has 'gid',     required => 1, is => 'ro';
has 'rdev',    required => 1, is => 'ro';
has 'size',    required => 1, is => 'ro';
has 'atime',   required => 1, is => 'ro';
has 'mtime',   required => 1, is => 'ro';
has 'ctime',   required => 1, is => 'ro';
has 'blksize', required => 1, is => 'ro';
has 'blocks',  required => 1, is => 'ro';
has '_data',   required => 1, is => 'ro';

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
