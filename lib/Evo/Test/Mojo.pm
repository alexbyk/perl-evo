package Evo::Test::Mojo;
use Evo -Export, '/::Item';

sub testm ($fn) : prototype(&) : Export {
  my $wfn = sub($continue) {
    my ($timeout, $cb_called);
    $fn->(sub { Mojo::IOLoop->stop; $continue->(); $cb_called++ });
    return if $cb_called;

    Mojo::IOLoop->timer(1 => sub { $timeout++; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    die "Timeout" if $timeout;
  };
  Evo::Test::Runner->dsl_add($wfn);
}

1;
