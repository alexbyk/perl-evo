package Evo::Promises;
use Evo;
use Evo '-Export *; :Deferred; :Promise';

sub promise($fn) : Export {
  my $d = Evo::Promises::Deferred::new(promise => my $p = Evo::Promises::Promise::new());
  $fn->(sub { $d->resolve(@_) }, sub { $d->reject(@_) });
  $p;
}

sub deferred : Export :
  prototype() { Evo::Promises::Deferred::new(promise => Evo::Promises::Promise::new()); }

1;
