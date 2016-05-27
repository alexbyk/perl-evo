package Evo::Lib;
use Evo '-Export *; Carp croak; ::Bare';
use Time::HiRes qw(CLOCK_MONOTONIC);

PATCH: {
  no warnings 'once';
  *debug               = *Evo::Lib::Bare::debug{CODE};
  *monkey_patch        = *Evo::Lib::Bare::monkey_patch{CODE};
  *monkey_patch_silent = *Evo::Lib::Bare::monkey_patch_silent{CODE};
}

export qw(debug monkey_patch monkey_patch_silent);

my $HAS_M_TIME = eval { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); 1; };

export_anon steady_time => $HAS_M_TIME
  ? sub { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); }
  : \&Time::HiRes::time;


# combine higher order function without any protection and passing arguments
sub ws_fn : Export {
  my $cb = pop or croak "Provide a function";
  return $cb unless @_;
  $cb = $_->($cb) for reverse @_;
  $cb;
}

# call each $next exactly once or die. Bypas args to cb
sub combine_thunks : Export {

  my $_cb = pop or croak "Provide a function";
  return $_cb unless my @hooks = @_;

  my @args;
  my $cb = sub { $_cb->(@args) };

  foreach my $cur (reverse @hooks) {
    my $last  = $cb;
    my $count = 0;
    my $safe  = sub { $last->() unless $count++ };

    $cb = sub { $cur->($safe); die "\$next in hook called $count times" unless $count == 1 };

  }

  sub { @args = @_; $cb->(); return };
}


1;
