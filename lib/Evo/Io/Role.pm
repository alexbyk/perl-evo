package Evo::Io::Role;
use Evo '-Role *';

use Fcntl qw(F_SETFL F_GETFL O_NONBLOCK);

sub _fopt($flag, $debug, $s, $val=undef) {
  my $flags = fcntl($s, F_GETFL, 0) or _die $debug;
  return !!($flags & $flag) + 0 if @_ == 3;
  fcntl($s, F_SETFL, $flags | $flag) or _die $debug;
  $s;
}

sub io_non_blocking : Role { _fopt(O_NONBLOCK, "nb", @_) }

1;
