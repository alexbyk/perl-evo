package Evo::Test;
use Evo '-Export *; ::Mock';

export_proxy '::Mock', qw(get_original call_original);

sub mock ($name, @args) : Export {
  Evo::Test::Mock->create_mock($name, @args);
}


1;

=head1 SYNOPSYS

  {

    package My::Foo;    ## no critic
    sub foo {'FOO'}
  }

  my $mock = mock('My::Foo::foo', sub { say "Mocked"; call_original() });
  my $res = My::Foo->foo();
  say $res;                            # FOO
  say $mock->get_call(0)->result;      # FOO
  say $mock->calls->[0]->args->[0];    # "My::Foo"

=head1 MOCK

  my $mock = mock('My::Foo::foo', 1); # call original
  my $mock = mock('My::Foo::foo', 0); # don't call anything
  my $mock = mock('My::Foo::foo', sub { say "Mocked"; call_original() });

  # rethrow error 
  my $mock = mock('My::Foo::foo', rethrow => 1, patch => sub { die "Foo\n" });

  my $res = My::Foo->foo();

  # restore
  undef $mock;

Create a mock for the subroutine. The subroutine will be restored when the mock object is destroyed.
By default swallows all errors. You can pass C<rethrow> as true, in this case exceptions will be
recorder then rethrown up, so you will be able to catch them

=cut
