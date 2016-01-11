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

See the full example at the bottom of this doc L</"BUILDING REALM">

  package main;
  use Evo;

  {

    package My::Log;
    use Evo '-Comp *; -Realm *';
    sub msg($self, $msg) { say $msg }

    package My::MockLog;
    use Evo '-Comp *';
    sub msg($self, $msg) { say "MOCK" }
  };


  my $default = My::Log::new();
  my $mock    = My::MockLog::new();

  My::Log::realm $mock, sub {
    $default->realm_lord->msg('hello');    # MOCK
  };

  $default->realm_lord->msg('hello');      # hello

=head1 FUNCTIONS

=head2 realm

Start a new realm (the last argument) with the lord (the first argument).


  my $silent_log = My::Log::new(level => 1);
  My::Log::realm $silent_log, sub { };
  My::Log::realm $silent_log, 'arg1', 'arg2', sub { };

=head2 realm_lord

Get the lord of current realm. If we're not in the realm of the module, return the passed argument or die

  my $default = My::Log::new();
  my $lord    = My::Log::realm_lord($default);    # return current lord or $default
  $lord = $default->realm_lord;                   # the same ($default is an instance of My::Log)

  $lord = My::Log::realm_lord();                  # return current lord or die

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

  package My::MockLoopComp;
  use Evo '-Comp *';
  has stash => sub { {} };
  sub timer($self, $delay, $fn) { $self->stash->{count}++; $fn->() }

And now how to make it a lord:

  my $mock_loop = My::MockLoopComp::new();
  Evo::Loop::Comp::realm $mock_loop, sub {
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

    package My::MockLoopComp;
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
    my $mock_loop = My::MockLoopComp::new();

    # make mock loop a lord for this realm:
    Evo::Loop::Comp::realm $mock_loop, sub {
      $app->rename_later('alex');
    };

    is $app->name, 'alex';
    is $mock_loop->stash->{count}, 1;

  };


  loop_start();

  done_testing;

=head1 BUILDING REALM

To build component with realm, just import C<Evo::Realm '*'> into the component's package.

    package My::Log;
    use Evo '-Comp *; -Realm *';
    sub msg($self, $msg) { say $msg }

After that you can use it like this:

  my $mock    = My::MockLog::new();
  My::Log::realm $mock, sub {
    $default->realm_lord->msg('hello');    # MOCK
  };

This form isn't convenient: it's lot of typing and you can miss C<-E<gt>realm_lord> part by accident. Let's improve our log and make it simple like C<mylog('hello')>

    package My::Lib;
    use Evo '-Export *';
    use constant DEFAULT_LOG => My::Log::new();

    sub mylog : Export { DEFAULT_LOG->realm_lord->msg(@_) }

This library does all boring stuff for us. Now we can import it C<use My::Lib '*';> and use C<mylog> function.

The full improved example from the SYNOPSYS:


  package main;
  use Evo;

  {

    package My::Log;
    use Evo '-Comp *; -Realm *';
    sub msg($self, $msg) { say $msg }

    package My::MockLog;
    use Evo '-Comp *';
    sub msg($self, $msg) { say "MOCK" }

    package My::Lib;
    use Evo '-Export *';
    use constant DEFAULT_LOG => My::Log::new();

    sub mylog : Export { DEFAULT_LOG->realm_lord->msg(@_) }

  };

  My::Lib->import('*');    # use My::Lib '*'; in real code
  my $mock = My::MockLog::new();

  My::Log::realm $mock, sub {
    mylog('hello');        # MOCK
  };

  mylog('hello');          # hello


=cut
