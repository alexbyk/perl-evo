package Evo::Io::Handle;
use Evo '-Comp::Out *; Symbol gensym';

with '-Io::Handle::Role';

sub open_nb($mode, $expr, @list) {
  my $fh = Evo::Io::Handle::init(gensym());
  open($fh, $mode, $expr, @list) || die "open: $!";    ## no critic
  $fh->handle_non_blocking(1);
}

sub open_nb_anon {
  my $fh = Evo::Io::Handle::init(gensym());
  open($fh, '>', undef);
  $fh->handle_non_blocking(1);
}


1;
