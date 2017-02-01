package Evo::Test;
use Evo '-Export *; ::Mock';

export_proxy '::Mock', qw(get_original call_original);

sub mock ($name, $mock=0) : Export {
  Evo::Test::Mock->create_mock($name, $mock);
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

  my $res = My::Foo->foo();

=cut
