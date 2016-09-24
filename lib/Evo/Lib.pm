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

sub eval_want : Export {
  my ($want, $fn) = (shift, pop);
  if (!defined $want) {
    eval { $fn->(@_); 1 } or return;
    return sub { };
  }
  elsif (!$want) {
    my $res;
    eval { $res = $fn->(@_); 1 } or return;
    return sub {$res};
  }
  else {
    my @res;
    eval { @res = $fn->(@_); 1 } or return;
    return sub {@res};
  }
}

sub try : prototype(&$;$) : Export {
  my ($try, $catch, $fin) = @_;
  my $call = eval_want wantarray, $try;
  $call = eval_want wantarray, my $e = $@, $catch if !$call && $catch;
  if ($call) {
    $fin->() if $fin;
    return $call->();
  }
  $e = $@;
  $fin->() if $fin;
  die $e;
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

=head1 FUNCTIONS 

=head2 steady_time

Return an array contains only uniq elements

=head2 uniq(@args)

Return an array contains only uniq elements

=head2 strict_opts($level, $hash, @keys)


  sub myfunc(%opts) { my ($foo, $bar) = strict_opts(1, \%opts, 'foo', 'bar'); }

Get a C<$hash> and return values in order defined by C<@keys>. If there are superfluous keys in hash, throw an error. This will help you to protect your functions from bugs "passing wrong keys"

C<$level> determines how many frames to skip. In most cases it's C<1>

=head2 try 

  use Evo '-Lib try';

  # try + catch
  try { die "MyError" } sub($e) { say "Catched: $e" };

  # try + catch + finally
  try sub { die "MyError" }, sub($e) { say "Catched: $e" }, sub { say "Finally" };

The behaviour is just like JS's try catch finally with one exception: return
statement in finally block doesn't matter, because in perl every subroitine
returns something (and because it's more "as expected") 

There is a similar and popular Try::Tiny, but it has a flaw: it can't catch errors in finally block.
This module deal with this case the right way: If "finally" block throws an
error, the exception will be thrown.

Also this module is much faster and more tiny(~30 lines of code).

=head3 Brief description

Firstly "try_fn" will be executed. If it throws an error, "catch_fn" will be
executed with that exception as an argument and perl won't die. "finally_fn",
if exists, will be always executed but the return value of finally_fn will be ignored.

=head3 Examples

  # fin; result: ok
  my $res = try sub { return "ok" }, sub {...}, sub { print "fin; " };
  say "result: ", $res;

  # fin; result: catched
  $res = try sub { die "Error\n" }, sub { return "catched" }, sub { print "fin; " };
  say "result: ", $res;

"Catch" block can be skipped if we're interesting only in "finally"

  # print fin than dies with "Error" in $@
  $res = try sub { die "Error\n" }, undef, sub { print "fin\n" };

If "finally" fn throws an exception, it will be rethrown as expected

  # die in finally block with "FinError\n" in $@
  $res = try sub { 1 }, sub {...}, sub { die "FinError\n" };


Deals correctly with C<wantarray>

  # 1;2;3
  local $, = ';';
  say try sub { wantarray ? (1, 2, 3) : 'One-Two-Three' }, sub {...};

  # One-Two-Three
  say scalar try sub { wantarray ? (1, 2, 3) : 'One-Two-Three' }, sub {...};


=head2 eval_want

Invokes a last argument with the context of the first C<void: undef, scalar: '', list: 1>,
passing remaining arguments. If the function throws an error, returns nothing
and sets <$@>. So returned value can answer the question was an invocation
successfull or not

Mostly for internal purposes to deal correctly with C<wantarray> and for creating a spy. Short:
it allows to intercept execution flow without loosing a context

  use Evo '-Lib eval_want';

  sub add2($val) { $val + 2 }

  sub create_spy($fn) {
    sub {
      warn "[spy] context: ", wantarray,  "; args: ", join ';', @_;
      my $call = eval_want(wantarray, @_, $fn) or die $@;
      $call->();
    };
  }

  my $spy = create_spy(\&add2);
  say $spy->(10);

As you can se, we just pass given context C<wantarray> to the eval_want

=cut
