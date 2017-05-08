package Evo::Test::Runner;
use Evo -Class, '-Lib try; /::Item';

has tests => sub { [] };
has hooks => sub { {before => [], after => [], around => []} };
has $_, optional for qw(current_test prev_test);

our $CURRENT;

sub CURRENT($me) { $CURRENT || die "Not in DSL"; }

sub dsl_add ($me, $fn, $level = 1) {
  my $cur      = $me->CURRENT;
  my $filename = 'MOCK';
  my $index    = 'MOCK';
  my $item     = Evo::Test::Item->new(fn => $fn, filename => $filename, index => $index);
  $cur->add_item($item);
}


sub dsl_call ($self, $fn) {
  local $CURRENT = $self;
  $fn->();
}

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

    warn $test->status, $test->error ? ': ' . $test->error : '';
  }
}

1;
