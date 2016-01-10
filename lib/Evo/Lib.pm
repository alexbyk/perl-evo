package Evo::Lib;
use Evo '-Export *', -Util, 'Carp croak';
use Time::HiRes qw(CLOCK_MONOTONIC clock_gettime);

PATCH: {
  no warnings 'once';
  *Evo::Lib::debug        = *Evo::Util::debug{CODE};
  *Evo::Lib::monkey_patch = *Evo::Util::monkey_patch{CODE};
}

export qw(debug monkey_patch);

my $HAS_M_TIME = eval { clock_gettime(CLOCK_MONOTONIC); 1 };

export_anon steady_time => $HAS_M_TIME
  ? sub { clock_gettime(CLOCK_MONOTONIC); }
  : \&Time::HiRes::time;

sub ws_combine : Export {
  return unless @_;
  return $_[0] if @_ == 1;
  my @wrappers = reverse @_;
  sub {
    my $w = $_[0];
    $w = $_->($w) for @wrappers;
    $w;
  };
}

1;
