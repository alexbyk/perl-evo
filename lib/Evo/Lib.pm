package Evo::Lib;
use Evo '-Export *; Carp croak; ::Bare';
use Time::HiRes qw(CLOCK_MONOTONIC);

PATCH: {
  no warnings 'once';
  *debug        = *Evo::Lib::Bare::debug{CODE};
  *monkey_patch = *Evo::Lib::Bare::monkey_patch{CODE};
}

export qw(debug monkey_patch);

my $HAS_M_TIME = eval { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); 1; };

export_anon steady_time => $HAS_M_TIME
  ? sub { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); }
  : \&Time::HiRes::time;


sub ws_fn : Export {
  my $cb = pop or croak "Provide a function";
  return $cb unless @_;
  $cb = $_->($cb) for reverse @_;
  $cb;
}


1;
