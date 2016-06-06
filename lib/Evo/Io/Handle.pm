package Evo::Io::Handle;
use Evo '-Class::Out; -Loop *; Symbol gensym';

use Fcntl qw(F_SETFL F_GETFL O_NONBLOCK);

sub _fopt ($flag, $debug, $s, $val = undef) {
  my $flags = fcntl($s, F_GETFL, 0) or die "$debug: $!";
  return !!($flags & $flag) + 0 if @_ == 3;

  $flags = $val ? $flags | $flag : $flags & ~$flag or die "$debug: $!";
  fcntl($s, F_SETFL, $flags) or _die $debug;
  $s;
}

sub io_non_blocking { _fopt(O_NONBLOCK, "nb", @_) }

sub DESTROY($self) {
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  my $fd = fileno $self or return;
  loop_io_remove_fd $fd;
}

1;
