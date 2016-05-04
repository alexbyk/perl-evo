package Evo::Role;
use Evo '-Attr *; -Role::Exporter; -Lib::Bare';
use Evo '-Export *, -import, import_all:import';
use Evo 'Carp croak; Module::Load load';

our @CARP_NOT = ('Evo::Lib::Bare');

use constant ROLE_EXPORTER => Evo::Role::Exporter::new();
export 'ROLE_EXPORTER';

export_gen has => sub($class) {
  sub { ROLE_EXPORTER->add_attr($class, @_); };
};

export_gen role_methods => sub($class) {
  sub { ROLE_EXPORTER->add_methods($class, @_); };
};

export_gen role_gen => sub($class) {
  sub { ROLE_EXPORTER->add_gen($class, @_); };
};

export_gen role_proxy => sub($class) {
  sub { ROLE_EXPORTER->proxy($class, @_); };
};

export_gen requires => sub($role_class) {
  sub(@list) {
    my $hook = sub($dst) {
      no strict 'refs';    ## no critic
      *{"${dst}::$_"}{CODE}
        or croak qq#Role "$role_class" requires "$dst" to have method "$_"#
        for @list;
    };
    ROLE_EXPORTER->hooks($role_class, $hook);
  };
};


sub _attr_handler ($class, $code, @attrs) {
  if (grep { $_ eq 'Role' } @attrs) {
    Evo::Lib::Bare::find_subnames($class, $code);
    ROLE_EXPORTER->add_methods($class, Evo::Lib::Bare::find_subnames($class, $code));
  }

  return grep { $_ ne 'Role' } @attrs;
}

attr_handler \&_attr_handler;

1;

# VERSION

# ABSTRACT: Evo::Role - reuse code between components

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    # Evo::Load is only for one-file examples

    package Person::Human;
    use Evo '-Role *; -Loaded';
    has 'name';
    sub upper_name : Role { uc shift->name }

    package Person;
    use Evo '-Comp *';

    with ':Human';    # same as "Person::Human"; reuse Person::Human code
    sub intro { say "My name is ", shift->upper_name }

  };

  my $alex = Person::new(name => 'alex');
  $alex->intro;


=head1 DESCRIPTION

OO is considered an anti-pattern because it's hard to change base class and reuse the code written by other person (Fragile base class problem), and every refactoring makes OO applications low-tested or extra-tested. Component oriented programming doesn't have such weakness. It uses roles (like Moose's roles), or so called "mixins".

Because of that, Components are faster, simpler, and more reusable
Also Roles can protect you from method and attributes clashing, because all methods and attributes will be installed into one file

I'll write an article about this late (maybe)

Here is a breaf overview

=head2 Building and using component roles

To share method, add C<Role> tag. All attributes are shared automatically. In our case method C<upper_name> and attribute C<name> are provided by role.

    # Person/Human.pm
    package Person::Human;
    use Evo '-Role *';
    has 'name';
    sub upper_name : Role { uc shift->name }

And to use it in the component

    # Person.pm
    package Person;
    use Evo '-Comp *';

    with ':Human';    # same as "Person::Human"; reuse Person::Human code

See L<Evo::Comp/"with">.

=head3 Shortcuts

C<Evo::Role> supports shortcuts, here C<:Human> in C<Person> is resolved to C<Person::Human>. This helps a lot during refactoring. See L<Evo/"shortcuts"> for more information

=head3 Storage agnostic

The good news are roles don't care what type of storage will be used by derived component (L<Evo::Comp::Hash>, L<Evo::Comp::Out> or others) - it will work. So you can do something like this:

  package Person;
  use Evo '-Comp *';
  with 'Person::Human';

  package PersonArray;
  use Evo '-Comp::Out *';
  with 'Person::Human';

  package main;
  use Evo;
  use Data::Dumper;
  my $person_hash = Person::new(name => 'foo');
  my $person_array = PersonArray::init([1, 2, 3], name => 'bar');

  # hash
  say Dumper $person_hash;

  # array
  say Dumper $person_array;

In the example above, C<Person> is based on hashes, while C<PersonArray> is based on arrays. They both use C<Person::Human> role.

Let's separate C<Person::Human> into 2 different roles;

    # Person/Human.pm
    package Person::Human;
    use Evo '-Role *';
    has 'name';

    # Person/LoudHuman.pm
    package Person::LoudHuman;
    use Evo '-Role *';

    requires 'name';
    sub upper_name : Role { uc shift->name }

    package Person;
    use Evo '-Comp *';

    with ':LoudHuman', ':Human';
    sub intro { say "My name is ", shift->upper_name }

C<Person::LoudHuman> provides method C<upper_name>. C<requires 'name'>, which is used by C<upper_name> ensures that derivered class has this method or attribute. (attributes should be described before L<Evo::Comp/"with">, to solve circular requirements, include all roles in one L<Evo::Comp/"with">)

=head3 features

=head4 role_gen

Creates generator, very similar to L<Evo::Export/"export_gen">

=head4 role_proxy

  role_proxy 'My::Another', 'My::Another2';

Proxy attributes and methods from one role to another

=head4 role_methods

C<:Role> attribute is preffered

=head4 requires

List method that should be available in component during role installation.
If you require attribute, describe it before L</"with">. If you have circular dependencies, load all roles in the single L</"with">.

=head2 Overriding methods

It's possible to override method in the derived class. By default you're protected from method clashing. But you can override role methods with L<Evo::Role/"overrides"> or C<Override> subroutine attribute. And because components are flat, you can easely acces role's methods (just like SUPER) - just use C<Role::Package::name> syntax.

  package main;
  use Evo;

  {

    package MyRole;
    use Evo '-Role *; -Loaded';
    has foo => 'FOO';
    sub bar : Role : {'BAR'}


    package MyComp;
    use Evo '-Comp *';

    overrides qw(foo);
    with 'MyRole';

    sub foo : Override { 'OVERRIDEN'; }
    sub bar : Override { 'OVERRIDEN' . ' ' . MyRole::bar(); }
  };


  my $comp = MyComp::new();
  say $comp->foo;    # OVERRIDEN
  say $comp->bar;    # OVERRIDEN BAR

Many overriden methods is a signal for refactoring. But sometimes it's ok to provide a "default" method for testing, or override 3d party library


=cut
