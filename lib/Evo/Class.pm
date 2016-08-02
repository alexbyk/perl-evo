package Evo::Class;
use Evo '-Export export_proxy; Evo::Class::Gen; Evo::Class::Meta';

my $GEN_IMPL = eval { require Evo::Class::Gen::XS; 1 } ? 'Evo::Class::Gen::XS' : 'Evo::Class::Gen';

sub new ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->gen->gen_new;
}

sub init ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->gen->gen_init;
}

sub import ($me, @list) {
  my $caller = caller;
  Evo::Class::Meta->register($caller, $GEN_IMPL);
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


sub attr_exists ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->gen->gen_attr_exists;
}

sub attr_delete ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->gen->gen_attr_delete;
}

sub attrs_map ($me, $dest) : ExportGen {
  Evo::Class::Meta->find_or_croak($dest)->gen->gen_attrs_map;
}

sub has ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $parsed = Evo::Class::Meta->parse_attr(@opts);
    Evo::Class::Meta->find_or_croak($dest)->reg_attr($name, $parsed);
  };
}

sub has_over ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $parsed = Evo::Class::Meta->parse_attr(@opts);
    Evo::Class::Meta->find_or_croak($dest)->reg_attr_over($name, $parsed);
  };
}

sub _extend ($me, $dest, @parents) {
  my $meta = Evo::Class::Meta->find_or_croak($dest);
  my $gen  = $me->class_of_gen->find_or_croak($dest);
  my @names;
  foreach my $par (@parents) {
    $par = Evo::Internal::Util::resolve_package($dest, $par);
    push @names, $meta->extend_with($par);
  }
  $me->class_of_gen->find_or_croak($dest)->sync_attrs($meta->attrs->%*);
  foreach my $name (@names) {
    my $sub = $gen->gen_attr($name, $meta->attrs->{$name}->%*);
    my $fn = Evo::Internal::Util::monkey_patch $dest, $name, $sub;
  }
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

=head2 Mixins programming

A new promising inject-code programming concepts based on mixins. Documentation will be available if someone will be willing to help write it.

=head2 Why not OO and Moose like?

The main difference is C<Evo> stores attributes outside the object, so any ref could be an object, while Moose allow you to use only hashes. This makes possible, for example, to avoid delegating C<$stream-E<gt>fh> and makes a code faster. Also avoiding hashes improves performance 


The syntax differs from Moose too, I fixed most frustating parts of it. It's not Moose-compatible at all. C<Evo::Class> is more strict by default and prevents many errors.

Every class is also a role. We don't use perl's C<@ISA> OO inheritance. Code reuse is based on so called "mixins".
This concept doesn't suffer a C<fragile base class problem> from traditional OO

Every class is also an interface and can be used to check the shape of other classes.

A tiny amount of code means less bugs. You can make a code review in 5 minutes and understand everything.

These advantages make C<Evo::Class> perfect for both "corporate level" and "small" projects

=head1 XS AND PERFORMANCE

This module will automatically load and use XS generator, if available. Install L<Evo::XS> module to get benefits. PP is only "fast enough", buth with XS this module is one of the fastest in CPAN. (Should be 50-100% faster than similar hash-based modules, see L<https://github.com/alexbyk/perl-evo/tree/master/bench>)

=head1 Usage

=head2 creating an object

  package My::Class;
  use Evo -Class;
  has 'simple';

You don't need to call something like C<__PACKAGE__-E<gt>meta-E<gt>make_immutable> unlike in L<Moose>, Evo objects are fast enough by design.

=head2 new

  my $foo = My::Class->new(simple => 1);
  my $foo2 = My::Class->new();

We're protected from common mistakes, because constructor won't accept unknown attributes.
You may think why not C<My::Class::new>? You're right. The first option isn't really necessary and even constructor doesn't use it at all. But I decided to leave it that way
because many developers are familiar with C<My::Class-E<gt>new> form. There is also an L</init> function for perfectionists

=head2 Storage

The big advantage of Evo object that it's not tied with hashes. You can use C<init> to bless and init any reference.

  package My::Obj;
  use Evo 'Evo::Class *, -new';    # load all except "new"

  sub new ($me, %opts) {
    $me->init([], %opts);
  }

  package main;
  use Evo;
  say My::Obj->new();

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

You should now that using this feature is an antipattern in the mose of the cases. L</default> is preferable if you're not sure

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
    sub greet : Over { }


This differs from traditional OO style. With compoment programming, you should reuse code via L<Evo::Class::Role> or just organize classes with independed pieces of code like "mixing". So, try to override less

=head1 FUNCTIONS


This functions will be exported by default even without export list C<use Evo::Class>; You can always export something else like C<use Evo::Class 'has';> or export nothing C<use Evo::Class (); >

=head2 META

Return current L<Evo::Class::Meta> object for the class

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

=head2 attr_exists

=head2 attr_delete

  my $alex = My::Human->new(gender => 'male', age => 31);
  say $alex->attr_exists('age') ? 'exists' : 'not';
  say $alex->attr_delete('age');
  say $alex->attr_exists('age') ? 'exists' : 'not';

Like C<exists> and C<delete> but for attributes and check if attribute was registered (croak otherwise).

=head2 attrs_map

Return a list of key-values of attributes. Because attributes are stored outside of objects, use this method instead of dumping object

  my $alex = My::Human->new(gender => 'male', name => 'alex');
  use Data::Dumper;
  say Dumper {$alex->attrs_map}; # instead of say Dumper $alex;

Pay attention, every registered attribute will be listed here, even not-existing (with undef as a value).
To check if an attribute was settled, see L</attr_exists>

=head1 CODE ATTRIBUTES

  sub foo : Over { 'OVERRIDEN'; }

Mark name as overridden. See L<Evo::Role/"Overriding methods">

=cut
