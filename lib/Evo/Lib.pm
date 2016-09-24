package Evo::Lib;
use Evo '-Export *; Carp croak';

sub uniq : Export {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub strict_opts ($hash, $keys, $level = 1) : Export {
  my %opts = %$hash;
  my @opts = map { delete $opts{$_} } @$keys;
  if (my @remaining = keys %opts) {
    local $Carp::CarpLevel = $level;
    croak "Unknown options: ", join ',', @remaining;
  }
  @opts;
}

# marked as deprecated 24.09.2016
#use Time::HiRes qw(CLOCK_MONOTONIC);
#my $HAS_M_TIME = eval { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); 1; };
#export_code steady_time => $HAS_M_TIME
#  ? sub { Time::HiRes::clock_gettime(CLOCK_MONOTONIC); }
#  : sub { Time::HiRes::time() };
#

# marked as not useful at  24.09.2016
# combine higher order function without any protection and passing arguments
#sub ws_fn : Export {
#  my $cb = pop or croak "Provide a function";
#  return $cb unless @_;
#  $cb = $_->($cb) for reverse @_;
#  $cb;
#}

# marked as not useful at  24.09.2016
# call each $next exactly once or die. Bypas args to cb
#sub combine_thunks : Export {
#
#  my $_cb = pop or croak "Provide a function";
#  return $_cb unless my @hooks = @_;
#
#  my @args;
#  my $cb = sub { $_cb->(@args) };
#
#  foreach my $cur (reverse @hooks) {
#    my $last  = $cb;
#    my $count = 0;
#    my $safe  = sub { $last->() unless $count++ };
#
#    $cb = sub { $cur->($safe); die "\$next in hook called $count times" unless $count == 1 };
#
#  }
#
#  sub { @args = @_; $cb->(); return };
#}


1;

=head2 steady_time

Return an array contains only uniq elements

=head2 uniq(@args)

Return an array contains only uniq elements

=head2 strict_opts($level, $hash, @keys)


  sub myfunc(%opts) { my ($foo, $bar) = strict_opts(1, \%opts, 'foo', 'bar'); }

Get a C<$hash> and return values in order defined by C<@keys>. If there are superfluous keys in hash, throw an error. This will help you to protect your functions from bugs "passing wrong keys"

C<$level> determines how many frames to skip. In most cases it's C<1>

=cut
