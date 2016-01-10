package Evo::Ee;
use Evo '-Comp::Role *';
use Carp 'croak';
use List::Util 'first';

requires 'ee_events';

# [name, cb]
has ee_data => sub { [] };

sub ee_check($self, $name) : Role {
  croak qq{Not recognized event "$name"} unless first { $_ eq $name } $self->ee_events;
  $self;
}

sub on($self, $name, $fn) : Role {
  push $self->ee_check($name)->ee_data->@*, [$name, $fn];
  $self;
}

sub ee_remove($self, $name, $fn) : Role {
  my $data = $self->ee_check($name)->ee_data;
  defined(my $index = first { $data->[$_][0] eq $name && $data->[$_][1] == $fn } 0 .. $#$data)
    or return $self;
  splice $data->@*, $index, 1;
  $self;
}

sub emit($self, $name, @args) : Role {
  $_->($self, @args) for my @listeners = $self->ee_listeners($name);
  @listeners;
}

sub ee_listeners($self, $name) : Role {
  map { $_->[1] } grep { $_->[0] eq $name } $self->ee_data->@*;
}

1;

=head1 SYNOPSYS


  package main;
  use Evo;

  {

    package My::Comp;
    use Evo '-Comp *';
    with '-Ee';

    # define available events
    sub ee_events {qw( connection close )}

  }

  my $comp = My::Comp::new();

  # subscribe on the event
  $comp->on(connection => sub($self, $id) { say "got $id" });

  # emit event
  $comp->emit(connection => 'MyID');

=head1 DESCRIPTION

EventEmitter role for component

=head1 REQUIREMENTS

This role requires method C<ee_events> to be implemented in a derived class. It should return a list of available event names. Each invocation of L</"on"> and L</"ee_remove"> will be compared with this list and in case it doesn't exist an exception will be thrown

  # throws Not recognized event "coNNection"
  $comp->on(coNNection => sub($self, $id) { say "got $id" });

This will prevent people who use your component from the most common mistake in EventEmitter pattern.


=head1 METHODS

=head2 on

Subscbibe 

  $comp->on(connection => sub($self, @args) { say "$self got: " . join ';', @args });

The name of the event will be checked using C<ee_events>, which should be implemented by component and return a list of available names


=head2 emit

Emit an event. The component will be passed to the event as the first argument,  you can provide additional argument to the subscriber

  $comp->emit(connection => 'arg1', 'arg2');

=head2 ee_remove

Remove listener from the event by the name and subroutine.

  my $sub;
  $comp->on(connection => $sub = sub {"here"});
  $comp->ee_remove(connection => $sub);

The name of the event will be checked using C<ee_events>, which should be implemented by component and return a list of available names



=head2 ee_listeners

  my @listeners =  $comp->ee_listeners('connection');

A list of listeners of the event. Right now a name wouldn't be checked, but this can be changed in the future

=head2 ee_check

  $comp = $comp->ee_check('connection');

Check the event. If it wasn't in the derivered list returned by C<ee_events>, an exception will be thrown.


=cut


