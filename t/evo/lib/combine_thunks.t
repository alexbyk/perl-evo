use Evo 'Test::More; -Lib *';
use Evo::Internal::Exception;

like exception { combine_thunks() }, qr/provide.+$0/i;

my @got;

# empty
combine_thunks(sub { @got = @_ })->(1, 2);
is_deeply \@got, [1, 2];

# ok
my @log;

sub logh($n) {
  sub($next) { push @log, $n; $next->() }
}

combine_thunks(logh(1), logh(2), sub { @got = @_ })->(1, 2);
is_deeply \@got, [1, 2];
is_deeply \@log, [1, 2];

# too_many_times
@log = ();

sub log_bad($n) {
  sub($next) { push @log, $n; $next->(); $next->(); }
}

like exception {
  combine_thunks(log_bad(1), log_bad(2), sub { @got = @_ })->(1, 2);
},
  qr/2 times/;
is_deeply \@got, [1, 2];
is_deeply \@log, [1, 2];


# zero times
like exception {
  combine_thunks(sub { }, sub { })->();
}, qr/0 times/;
is_deeply \@got, [1, 2];
is_deeply \@log, [1, 2];

done_testing;
