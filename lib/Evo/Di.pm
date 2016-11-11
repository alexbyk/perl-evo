package Evo::Di;
use Evo -Class, '-Class::Attrs ECA_REQUIRED';
use Evo 'Module::Load load; Module::Loaded is_loaded; Carp croak';

has di_stash => sub { {} };

our @CARP_NOT = ('Evo::Class::Attrs');

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
    _croak_cirk(@stack, $cur) if $in_stack{$cur}++;
    push @stack, $cur, @pending;
  }

  $self->{di_stash}{$key};
}

sub provide ($self, %args) {
  foreach my $k (keys %args) {
    croak qq#Already has key "$k"# if exists $self->{di_stash}{$k};
    $self->{di_stash}{$k} = $args{$k};
  }
}

sub _croak_cirk (@path) { croak "Circular dependencies detected: " . join(' -> ', @path); }

sub _croak ($cur_key, $req_key) {
  croak qq#Can't load dependency "$cur_key" for class "$req_key"#;
}

# _di_list_pending - return Classes for the next resolve cycle
# the code is scary, but well tested

# 1) special dot syntax.
# - check My::Class.->{key}. Assign to var because perl populates
# - undef->{foo}{bar} and undef->{foo} becomes true.
# - if $hash is true and not a hash ref, it's missuse, croak even if not required
# - croak if .dep is required and $hash{dep} doesn't exists
# - don't add to results.
#
# 2) class
# - list only missing keys
# - try to load as class and return as result if loaded
# - if not, croak if dependency is required

sub _di_list_pending ($self, $req_key) {
  return unless $req_key->can('META');
  my @results;
  foreach my $slot ($req_key->META->{attrs}->slots) {
    next if !(my $k = $slot->{inject});

    if ($k =~ /^\..+/) {
      my $hash = $self->{di_stash}{"$req_key."};
      croak(qq#"$req_key." should be a hash ref#) if ($hash && (ref $hash ne 'HASH'));
      _croak($k, $req_key) if (!exists $hash->{(substr($k, 1))} && $slot->{type} == ECA_REQUIRED);
    }
    else {    # class
      next if exists $self->{di_stash}{$k};
      my $loaded = is_loaded($k) || eval { load($k); 1 };
      do { push @results, $k; next; } if $loaded;
      _croak($k, $req_key) if $slot->{type} == ECA_REQUIRED;
    }
  }

  @results;
}

# pass only existing key/values to ->new, skip missing
sub _di_build ($self, $key) {
  return $key->new() unless $key->can('META');
  my @opts;

  my $dot_stash = $self->{di_stash}{"$key."};
  foreach my $slot ($key->META->{attrs}->slots) {
    next unless my $k = $slot->{inject};
    if ($k =~ /^\..+/) {
      my $dk = substr($k, 1);
      push @opts, $slot->{name}, $dot_stash->{$dk} if exists $dot_stash->{$dk};
    }
    else {
      push @opts, $slot->{name}, $self->{di_stash}{$k} if exists $self->{di_stash}{$k};
    }
  }
  $key->new(@opts);
}


1;

# ABSTRACT: Dependency injection

=head1 SYNOPSYS

  use Evo -Di;

  {

    package My::C1;
    use Evo -Class, -Loaded;
    has c2 => inject 'My::C2';

    # dot notation
    has host => inject '.ip';
    has port => inject '.port';

    package My::C2;
    use Evo -Class, -Loaded;
    has c3 => inject 'My::C3';

    package My::C3;
    use Evo -Class, -Loaded;
    has foo => inject 'FOO';

  }

  my $di = Evo::Di->new();

  # provide some value in stash wich will be available as dependency 'FOO'
  $di->provide(FOO => 'FOO value');

  # provide config using dot notation
  $di->provide('My::C1.' => {ip => '127.0.0.1', port => '3000'});

  my $c1 = $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1 == $di->single('My::C1');
  say $c1->c2->c3 == $di->single('My::C3');
  say $c1->c2->c3->foo;    # FOO value

  say $c1->host;           # 127.0.0.1
  say $c1->port;           # 3000

=head1 INJECTION

Injection is a value of C<inject> option in L<Evo::Class>. Use it this way

If you need to describe a dependency of some class, write this class
  
  has dep => inject 'My::Class';

This class will be build, resolved and injected

If you need to provide a global value, for example, processor cores, you can use UPPER_CASE constants. You need to provide a value for this dependency

  has cores => inject 'CORES';
  $di->provide(CORES => 8);

If you need to provide some constant for class, use it this way

  has limit => inject => 'My::Class/LIMIT';
  $di->provide(My::Class/LIMIT => 8);

For convineince, there is a special "dot notation". C<inject> field should start with dot and dependency in format "Class::Name."(dot at the and) should be a hash reference, containing keys

  has ip => inject '.ip';
  $di->provide('My::C1.' => {ip => '127.0.0.1', port => '3000'});

Usefull for configuration

=head1 ATTRIBUTES

=head2 di_stash

A hash reference containing our dependencies (single instances)

=head1 METHODS

=head2 provide($self, $key, $v)

You can put in stash any value as a dependency

  $di->provide('SOME_CONSTANT' => 33);
  say $di->single('SOME_CONSTANT'), 33;

  $di->provide('My::C1.' => {ip => '127.0.0.1', port => '3000'});

=head2 single($self, $key)

If there is already a dependency with this key, return it.
If not, build it, resolving a dependencies tree. Has a protection from circular
dependencies (die if A->B->C->A)

=head3 Resolving dependencies tree

Building a class means resolving a dependencies tree. Dependency is a value of C<inject> option if a C<$key> is a L<Evo::Class>

This module will try to load every dependency from the stash which are not dot notations, if it's missing, consider it as a class name, load it and to build it with C<new> method and resolving it's dependency, if it's a L<Evo::Class> too.

If the dependency can't be resolved (no value in stash, package is missing), there are 2 possible situations:

If dependency is dot notation, module will check if it's provided and die, if it's missing and attribute is required.

=head4 optional dependency

If an attribute is L<Evo::Class/optional>, such attribute will be ignored.

=head4 required dependency

If an attribute isrequired, die.

=cut
