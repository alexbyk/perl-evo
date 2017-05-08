package Evo::Test::Runner;
use Evo -Class, '-Lib try';

has tests => sub { [] };
has hooks => sub { {before => [], after => [], around => []} };
has $_, optional for qw(current_test prev_test);

sub add_item ($self, $test) {
  push $self->tests->@*, $test;
}

sub run($self) {
  foreach my $test ($self->tests->@*) {
    my $continue = sub { $test->status('ok') };
    try sub {
      $test->invoke($continue);
      $test->status('failed')->error('Abondoned') unless $test->status eq 'ok';
    }, sub($e) { $test->status('error')->error($e) };

    warn $test->status;
    warn $test->error if $test->error;
  }
}

1;
