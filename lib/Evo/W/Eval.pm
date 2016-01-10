package Evo::W::Eval;
use Carp 'croak';
use Evo '-Eval *', '-Export *';


sub w_eval_run($catch) : Export {
  sub($next) {
    sub {
      my $call = eval_want(wantarray, @_, $next);
      return $call->result if $call;
      $catch->($@);
      return;
    };
  };
}

1;
