package Evo::Class;
use Evo '-Export export_proxy; Evo::Class::Meta';

sub new ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->attrs->gen_new;
}

sub import ($me, @list) {
  my $caller = caller;
  Evo::Class::Meta->register($caller);
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
}

sub META ($me, $dest) : ExportGen {
  sub { Evo::Class::Meta->find_or_croak($dest); };
}

sub requires ($me, $dest) : ExportGen {

  sub (@names) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    $meta->reg_requirement($_) for @names;
  };
}


sub Over ($dest, $code, $name) : Attr {
  Evo::Class::Meta->find_or_croak($dest)->mark_as_overridden($name);
}


sub has ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my @parsed = Evo::Class::Meta->parse_attr(@opts);
    Evo::Class::Meta->find_or_croak($dest)->reg_attr($name, @parsed);
  };
}

sub has_over ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my @parsed = Evo::Class::Meta->parse_attr(@opts);
    Evo::Class::Meta->find_or_croak($dest)->reg_attr_over($name, @parsed);
  };
}

sub extends ($me, $dest) : ExportGen {
  sub(@parents) {
    Evo::Class::Meta->find_or_croak($dest)->extend_with($_) for @parents;
  };
}

sub implements ($me, $dest) : ExportGen {
  sub(@parents) {
    Evo::Class::Meta->find_or_croak($dest)->check_implementation($_) for @parents;
  };
}


sub with ($me, $dest) : ExportGen {

  sub (@parents) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $parent (@parents) {
      $meta->extend_with($parent);
      $meta->check_implementation($parent);
    }
  };
}


1;

=head1 SYNOPSYS


  package main;
  use Evo;

  {

    package My::Human;
    use Evo -Class, -Loaded;

    has 'name' => 'unnamed';
    has 'gender', is => 'ro', required => 1;
    has age => check => sub($v) { $v >= 18 };
    sub greet($self) { say "I'm " . $self->name }
  }

  my $alex = My::Human->new(gender => 'male');

  # default value "unnamed"
  say $alex->name;

  # fluent design
  $alex->name('Alex')->age(18);
  say $alex->name, ': ', $alex->age;

  # method
  $alex->greet;

  ## ------------ protecting you from errors, uncomment to test
  ## will die, gender is required
  #My::Human->new();

  ## will die, age must be >= 18
  #My::Human->new(age => 17, gender => 'male');
  #My::Human->new(gender => 'male')->age(17);

  # --------- code reuse
  {

    package My::Developer;
    use Evo -Class;
    with 'My::Human'; # extends 'My::Human'; implements 'My::Human';

    has lang => 'Perl';

    sub show($self) {
      $self->greet();
      say "I like ", $self->lang;
    }


  }

  my $dev = My::Developer->new(gender => 'male');
  $dev->show;


=head1 DESCRIPTION

Fast full featured post-modern Object oriented programming. Available both in PP and C. See L<https://github.com/alexbyk/perl-evo/tree/master/bench>

=head2 INTRO

This module doesn't use perl's @ISA inheritance. This module isn't Moose compatible by design

I decided to avoid mistakes of common OO practices. All derivered classes are flat. 
If a parent and a child both have a method with the same name,
an exception will be thrown untill you specifically mark that's the child's method is overriden (see </Overriding>). You will be glad how many mistakes can save this
decision.

So right now in C<Evo::Class> "multiple inheritance", (which was considered as an antipatern), is ok and a right way to reuse a code.

This module is rich enough to write big applications. If some "Moose" feature is missing (for example, lazy functions exists while lazy value are dropped out), that's because
I considered it as antipattern. As a result, this whole module is ~300 lines of code and covers all needs.

Also, this module saves a lot of typings by providing a "short" syntax.

And last, but not least, this module is suprisingly fast. Available both in PP and XS variants. So give it a try

=head1 Usage

=head2 creating an object

  package My::Class;
  use Evo -Class;
  has 'simple';

=head2 new

  my $foo = My::Class->new(simple => 1);
  my $foo2 = My::Class->new();

We're protected from common mistakes, because constructor won't accept unknown attributes.

=head2 Declaring attribute

  package My::Foo;
  use Evo '-Class *';

  has 'simple';
  has 'short' => 'value';
  has 'foo' => default => 'value', is => 'rw', check => sub {1};

=head2 Syntax

Simple rw attribute

  has 'simple';
  # has 'simple', is => 'rw';

Attribute with default value: short form

  has 'short' => 'value';
  # has 'short', default => 'value';

Full form

  has 'foo' => default => 'value', is => 'rw', check => sub {1};

=head3 Options

=head4 is

Can be 'rw' or 'ro'; Unlike Perl6 is 'rw' by default

=head4 default

Attribute will be filled with this value if isn't provided to the C<new> constructor You can't use references, but you can provide a coderef instead of value, in this case return value of an invocation of this function will be used.

  has ref => sub($class) { {} };
  has foo => default => sub($class) { [] };

This is a good way to init some attribute that should always exists. Arguments, passed to C<new> or C<init>  will be passed to the function without object itself (because there are no object yet). If you're expecting another behaviour, check L</lazy>

=head4 lazy

Like default, but will be filled at the first invocation, not in constructor, and an instance will be passed as the argument

  # pay attention, an instance is passed
  has foo => lazy => sub($self) { [] };

You should know that using this feature is an antipattern in the most of the cases. L</default> is preferable if you're not sure

=head4 required

  has 'foo', required => 1;

Attributes with this options are required and will be checked in C<new> and C<init>, an exception will be thrown if required attributes don't exist in arguments hash.

  has 'db', required => 'My::DB';

You can also pass any C<TRUE> value for storing in the L</META> of the class.

TODO: describe how to use it with dependency injection

=head4 check

You can provide function that will check passed value (via constuctor and changing), and if that function doesn't return true, an exception will be thrown.


  has big => check => sub { shift > 10 };

You can also return C<(0, "CustomError")> to provide more expressive explanation

  package main;
  use Evo;

  {

    package My::Foo;
    use Evo '-Class *';

    has big => check => sub($val) { $val > 10 ? 1 : (0, "not > 10"); };
  };

  my $foo = My::Foo->new(big => 11);

  $foo->big(9);    # will die
  my $bar = My::Foo->new(big => 9);    # will die


=head1 CODE REUSE

All methods, defined in a class (not imported) are public. Functions, imported from other modules, don't become public and don't make a mess.

All attributes are public.

Methods, generated somehow else, for example by C<*foo = sub {}>, can be marked as public by L<Evo::Class::Meta/reg_method>


=head2 Private methods

If you want to mark a method as private, use new C<lexical_subs> feature

  my sub private {'private'}

You can also use L<Evo::Class::Meta/mark_as_private>

=head2 Overriding

Evo protects you from method clashing. But if you want to override method or fix clashing, use L</has_over> function or C<:Override> attribute

    package My::Peter;
    use Evo -Class;
    with 'My::Human';

    has_over name => 'peter';
    sub greet : Over { ... }


This differs from traditional OO style. With compoment programming. If you want to call parent's method, call it by full name instead of C<SUPER>

    sub greet : Over { Some::Parent::greet() }

=head1 FUNCTIONS


This functions will be exported by default even without export list C<use Evo::Class>; You can always export something else like C<use Evo::Class 'has';> or export nothing C<use Evo::Class (); >

=head2 META

Return current L<Evo::Class::Meta> object for the class.

  use Data::Dumper;
  say Dumper __PACKAGE__->META->info;

See what's going on with the help of L<Evo::Class::Meta/info>

=head2 extends

Extends classes or roles

=head2 implements

Check if all required methods are implemented. Like interfaces

=head2 with

This does "extend + check implementation". Consider this example:


  package main;
  use Evo;

  {

    package My::Role::Happy;
    use Evo -Class, -Loaded;

    requires 'name';

    sub greet($self) {
      say "My name is ", $self->name, " and I'm happy!";
    }

    package My::Class;
    use Evo -Class;

    has name => 'alex';

    #extends 'My::Role::Happy';
    #implements 'My::Role::Happy';
    with 'My::Role::Happy';

  }

  My::Class->new()->greet();



C<My::Role::Happy> requires C<name> in derivered class. We could install shared code with C<extends> and then check implemantation with C<implements>. Or just use C<with> wich does both.

You may want to use C<extends> and C<implements> separately to resolve circular requirements, for example

=head1 CODE ATTRIBUTES

  sub foo : Over { 'OVERRIDEN'; }

Mark name as overridden. Overridden means it will override the "parent's" method with the same name without diying

=head2 WORKING WITH NON-EVO PARENT CLASSES

In some case you may wish to inherite from non-evo classes using C<@ISA>. Evo class won't prevent that, but it will check method clashing and you wouldn't be able to pass that inheritance to children because Evo don't use C<@ISA> (but you can reinherit alien classes directly in the child)

You can also reimplement clashing methods with C<:Over> attribute, if both of Evo parent and @ISA parent have the same method.


  use Evo;

  {

    package My::Evo::Parent;
    use Evo -Loaded, -Class;
    sub foo {'EVO'}

    package My::Isa::Parent;
    use Evo -Loaded, -Class;
    sub foo {'ISA'}

    package My::Child;
    use Evo -Class;
    use parent 'My::Isa::Parent';
    with 'My::Evo::Parent';

    # without this, an error will be thrown because Evo doesn't know
    # wich foo do you need here
    sub foo : Over { My::Evo::Parent::foo(@_) }

  }

  say My::Child->foo();    # EVO

This is actually a good thing, because it prevents you from most of the "multiple inheritance" errors.

=cut
