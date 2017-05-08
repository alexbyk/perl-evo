package Evo::Test::Lib;
use Evo -Export, '/::Item';

sub test ($fn) : prototype(&) Export {
  my $wfn = sub($cb) {
    $fn->();
    $cb->();
  };
  Evo::Test::Runner->dsl_add($wfn);
}

1;
