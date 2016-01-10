package Evo::Eval;
use Evo '-Export *; :Call';

sub eval_want : Export {
  my ($want, $fn) = (shift, pop);
  my $call;
  if (!defined $want) {
    eval { $fn->(@_); 1 } or return;
    $call->{wanted} = undef;
  }
  elsif (!$want) {
    eval { $call->{result}->[0] = $fn->(@_); 1 } or return;
    $call->{wanted} = '';
  }
  else {
    eval { $call->{result} = [$fn->(@_)]; 1 } or return;
    $call->{wanted} = 1;
  }

  return bless $call, 'Evo::Eval::Call';
}


sub eval_try : prototype($$;$) : Export {
  my ($try, $catch, $fin) = @_;
  my $call = eval_want wantarray, $try;
  $call = eval_want wantarray, my $e = $@, $catch if !$call && $catch;
  if ($call) {
    $fin->() if $fin;
    return   if !defined wantarray;
    return $call->result;
  }
  else {
    $e = $@;
    $fin->() if $fin;
    die $e;
  }

}

1;

=head1 SYNOPSYS

  use Evo '-Eval *; -Want *';

  my $call = eval_want WANT_LIST, sub { return (1, 2, 3) };
  say $call->result;

  # try_fn, catch_fn, finally_fn
  my $res;
  $res = eval_try sub {...}, sub {...}, sub {...};
  $res = eval_try sub {...}, sub {...};
  $res = eval_try sub {...}, undef, sub {...};

  # try_want


=head2 Comparison with alternatives


=head3 with Try::Tiny

L<Try::Tiny> is very similar and PP too, but has design flaw, and can't catch this case:


  use Try::Tiny;
  sub foo { try {} finally { die "Foo" }; }

  eval { foo() };
  warn "Shouldn't be here";

Instead of throwing an exception, it can only report it to STDERR.

Also because C<Evo::Eval> doesn't try to pretend "blocks", it work's 3-5 times faster than Try::Tiny and is much more "tiny" (see source code)

=head3 with TryCatch

L<TryCatch> is 3-4 times faster, but has many dependencies written in C, doesn't support finally and has a lot of code compared to this module

=head3 with Guard

L<Guard> is written in C and has the same flaw as L<Try::Tiny> - can't deal with exceptions.


=head1 FUNCTION 

=head2 eval_try 

The semantic is similar to JS "try catch finally" block except returned value
of finally block doesn't matter.

Can be used as replacement of Guard.pm, Try::Tiny.pm and so on, because solves
their main problems If "finally" block throws an error, they can't catch it.

This module deal with this case the right way: If "finally" block throws an
error, the exception will be thrown.

It's behaviour is just like JS's try catch finally with one exception: return
statement in finally block doesn't matter, because in perl every subroitine
returns something (and because it's more "as expected") 

=head3 Brief description

Firstly "try_fn" will be executed. If it throws an error, "catch_fn" will be
executed with that exception as an argument and perl won't die. "finally_fn",
if exists, will be always executed but the return value of finally_fn will be ignored.

=head3 Examples

  # fin; result: ok
  my $res = eval_try sub { return "ok" }, sub {...}, sub { print "fin; " };
  say "result: ", $res;

  # fin; result: catched
  $res = eval_try sub { die "Error\n" }, sub { return "catched" }, sub { print "fin; " };
  say "result: ", $res;

"Catch" block can be skipped if we're interesting only in "finally"

  # print fin than dies with "Error" in $@
  $res = eval_try sub { die "Error\n" }, undef, sub { print "fin\n" };

If "finally" fn throws an exception, it will be rethrown as expected

  # die in finally block with "FinError\n" in $@
  $res = eval_try sub { 1 }, sub {...}, sub { die "FinError\n" };


Deals correctly with C<wantarray>

  # 1;2;3
  local $, = ';';
  say eval_try sub { wantarray ? (1, 2, 3) : 'One-Two-Three' }, sub {...};

  # One-Two-Three
  say scalar eval_try sub { wantarray ? (1, 2, 3) : 'One-Two-Three' }, sub {...};

=head2 eval_want

Mostly is for internal purposes to deal correctly with C<wantarray>

Invokes a last argument with the context of the first argument(see Evo::Want),
passing remaining arguments. If the function throws an error, returns nothing
and sets <$@>. So returned value can answer the question was an invocation
successfull or not


  use Evo '-Eval *';

  sub proxy {
    my $next = pop;
    my $call = eval_want(wantarray, @_, $next) or die $@;
    $call->result;
  }

  my @arr = proxy(1, 2, sub { say "want_list" if wantarray; return (1, 2) });
  say @arr;

=cut
