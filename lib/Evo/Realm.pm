package Evo::Realm;
use Evo '-Export *', '-Lib *';
use Evo::Util;
use Carp 'croak';
use Scalar::Util qw(refaddr blessed);


my %REALM;
sub REALM_DATA { \%REALM }

export_gen realm_lord => sub($key) {
  sub {
    return $REALM{$key} if exists $REALM{$key};
    $_[0] ? $_[0] : croak qq{not in realm of "$key"};
  };
};

export_gen realm => sub($key) {
  sub {
    my ($obj, $fn) = (shift, pop);
    local $REALM{$key} = $obj;
    $fn->(@_);
  };
};

1;

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    package My::Log;
    use Evo '-Comp *; -Realm *';
    has level => 3;

  };


  my $default = My::Log::new();
  my $silent = My::Log::new(level => 0);

  say $default->realm_lord->level;    # 3
  $silent->realm(
    sub {
      say $default->realm_lord->level;    # 0
    }
  );

  say $default->realm_lord->level;        # 3

=head1 FUNCTIONS

=head2 realm

Start a new realm (the last argument) with the lord (the first argument).


  my $silent_log = My::Log::new(level => 1);
  My::Lib::realm $silent_log, sub { };
  My::Lib::realm $silent_log, 'arg1', 'arg2', sub { };


=head2 realm_lord

Get the lord of current realm. If we're not in the realm of the module, return the passed argument or die

  my $lord = My::Log::realm_lord($default);         # return current lord or $default
  $lord = My::Log::realm_lord();                    # return current lord or die

=head1 TESTING


The good example of usage is L<Evo::Loop>. Consider you have following application:

  package My::App;
  use Evo '-Comp *; -Loop *';

  has name  => 'default';
  has delay => 10;

  sub rename_later($self, $name) {
    loop_timer $self->delay, sub { $self->name($name) }
  }

Method C<rename_later> starts a timer, that will eventually change C<name>. We need to test this behaviour: if the timer was fired only once and if the name was changed rightly. We can't test it simple way: 

  my $app = My::App::new(name => 'old');
  $app->rename_later('alex');
  is $app->name, 'alex';

That's because the name will be changed only after 10 seconds. Also we can't mock timer, because another tests are running right now and mocking event loop can break them.

If we were using singleton, we would either write slow blocking test with different loop for each one, or wouldn't be able to test this method at all. That's the weakness of "singleton" and "default" patterns

It's time for L<Evo::Realm> pattern. We're could create a different instance of the component (or even mocked one), create a C<realm> and make that instance to be in charge.

Let's write a mocked loop

{

  package My::Mock::Loop;
  use Evo '-Comp *';
  has stash => sub { {} };
  sub timer($self, $delay, $fn) { $self->stash->{count}++; $fn->() }
}

And now how to make it a lord:

  my $mock_loop = My::Mock::Loop::new();
  Evo::Loop::realm $mock_loop, sub {
    $app->rename_later('alex');
  };

We created a C<realm>. In that realm every invocation of L<Evo::Loop/"loop_timer"> will call a mocked version, but won't interfere with other timers, so we can run multiple tests in parallel.

Below is a full example, you can copy-paste-and-run it.

  package main;
  use Evo '-Loop *; Test::More; Time::HiRes time';

  # our app we're going to test
  {

    package My::App;
    use Evo '-Comp *; -Loop *';

    has name  => 'default';
    has delay => 10;

    sub rename_later($self, $name) {
      loop_timer $self->delay, sub { $self->name($name) }
    }

  };

  # Create a mock loop. It executes function blocking and count invocations
  {

    package My::Mock::Loop;
    use Evo '-Comp *';
    has stash => sub { {} };
    sub timer($self, $delay, $fn) { $self->stash->{count}++; $fn->() }
  }


  # simulate multiple tests to show that we don't break global timers
  loop_timer 0.5, sub { say "delay 0.5" };

  # here starts our test asynchroniously
  loop_postpone sub {

    # create mock loop and an instance of our app
    my $app = My::App::new(name => 'old');
    my $mock_loop = My::Mock::Loop::new();

    # make mock loop a lord for this realm:
    Evo::Loop::realm $mock_loop, sub {
      $app->rename_later('alex');
    };

    is $app->name, 'alex';
    is $mock_loop->stash->{count}, 1;

  };


  loop_start();

  done_testing;

=head1 BUILDING REALM

All function are universal and can be used as components method, as well as Lib methods
The key is the name of the class, wich did call C<use 'Evo::Realm *'>

=head1 As a lib

In this example the key is C<My::Lib>

  package main;
  use Evo;

  {

    package My::Log;
    use Evo '-Comp *';
    has 'level' => 3;
    sub log($self, $msg, $level = 3) { warn "[$level] $msg" if $level <= $self->level }


    package My::Lib;
    use Evo '-Realm *; -Export *';
    my $default = My::Log::new;

    # use current lord or default one
    sub glog : Export { realm_lord($default)->log(@_) }

  };

  My::Lib->import('*');

  # default level is 3
  glog('visible',   2);    # visible
  glog('invisible', 4);    # not

  # make realm with default level 1
  my $silent_log = My::Log::new(level => 1);
  My::Lib::realm $silent_log, sub {
    glog('visible',   1);    # visible
    glog('invisible', 2);    # not
  };

  # realm end, level is 3 again here
  glog('visible', 3);        # visible




=head2 As a component with method

Rewritten example, the key is the component's package itself

  package main;
  use Evo;

  {

    package My::Log;
    use Evo '-Comp *; -Realm *';
    has 'level' => 3;
    sub log($self, $msg, $level = 3) { warn "[$level] $msg" if $level <= $self->level }

  };


  my $default = My::Log::new();
  $default->realm_lord->log("visible",   3);
  $default->realm_lord->log('invisible', 4);    # not

  My::Log::new(level => 1)->realm(
    sub {
      $default->realm_lord->log('visible',   1);    # visible
      $default->realm_lord->log('invisible', 2);    # not
    }
  );

  # realm end, level is 3 again here
  $default->realm_lord->log('visible', 3);          # visible


Pay attention, we use C<$default-E<gt>realm_lord-E<gt>log()>

=cut
