package Evo::Di;
use Evo -Class, '-Class::Attrs ECA_REQUIRED';
use Evo 'Module::Load load; Module::Loaded is_loaded; Carp croak';

has di_stash => sub { {} };

sub single ($self, $key) {
  return $self->{di_stash}{$key} if exists $self->{di_stash}{$key};
  load $key;
  my @stack = ($key);

  my %in_stack;
  while (@stack) {
    my $cur = pop @stack;
    my @pending = _di_list_pending($self, $cur);
    if (!@pending) {
      $self->{di_stash}{$cur} = _di_build($self, $cur);
      next;
    }
    croak "Circular dependencies detected: " . join(' -> ', @stack, $cur) if $in_stack{$cur}++;
    push @stack, $cur, @pending;
  }

  $self->{di_stash}{$key};
}

# list only missing keys, that can be loaded, if required
# skip keys that can't be loaded and not required
sub _di_list_pending ($self, $key) {
  return unless $key->can('META');
  my @slots
    = grep { $_->{inject} && !exists $self->{di_stash}{$_->{inject}} } $key->META->{attrs}->slots;

  my @result;
  foreach my $slot (@slots) {
    my $loaded = is_loaded($slot->{inject}) || eval { load($slot->{inject}); 1 };
    do { push @result, $slot->{inject}; next; } if $loaded;
    croak qq#Can't load dependency "$slot->{inject}" for class "$key"#
      if $slot->{type} == ECA_REQUIRED;
  }
  @result;
}

# pass only existing key/values to ->new, skip missing
sub _di_build ($self, $key) {
  return $key->new() unless $key->can('META');
  my @opts = map {
    $_->{inject} && exists $self->{di_stash}{$_->{inject}}
      ? ($_->{name}, $self->{di_stash}{$_->{inject}})
      : ()
  } $key->META->{attrs}->slots;
  $key->new(@opts);
}


1;
# ABSTRACT: Dependency injection

=head1 SYNOPSYS

  use Evo -Di;

  {

    package My::C1;
    use Evo -Class, -Loaded;
    has c2 => required => 1, inject => 'My::C2';

    package My::C2;
    use Evo -Class, -Loaded;
    has c3 => required => 1, inject => 'My::C3';

    package My::C3;
    use Evo -Class, -Loaded;
    has foo => required => 1, inject => 'FOO';

  }

  my $di = Evo::Di->new();

  # provide some value in stash wich will be available as dependency 'FOO'
  $di->di_stash->{FOO} = 'FOO';

  # all dependencies will be resolved by Evo::Di
  my $c1 = $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1->c2->c3 == $di->single('My::C3');
  say $c1->c2->c3->foo;    # FOO

=head1 ATTRIBUTES

=head2 di_stash

A hash reference containing our dependencies (single instances)

=head1 METHODS

=head2 single($self, $key)

If there is already a dependency with this key, return it.
If not, build it, resolving a dependencies tree. Has a protection from circular
dependencies (die if A->B->C->A)

=head3 Resolving dependencies tree

Building a class means resolving a dependencies tree. Dependency is a value of C<inject> option if a C<$key> is a L<Evo::Class>

This module will try to load every dependency from the stash, if it's missing, consider it as a class name, load it and to build it with C<new> method and resolving it's dependency, if it's a L<Evo::Class> too.

If the dependency can't be resolved (no value in stash, package is missing), there are 2 possible situations:

=head4 optional dependency

If an attribute isn't C<required>, such attribute will be ignored.

=head4 required dependency

If an attribute is C<required>, die.

=cut


