package Evo::Class;
use Evo '::Gen::Hash GEN; -Class::Meta; -Class::Common meta_of';
use Evo '-Export *, -import';

export_proxy '-Class::Common',
  qw(new has has_overriden requires extends implements with MODIFY_CODE_ATTRIBUTES);

sub import ($me, @args) {
  my $caller = caller;
  meta_of($caller) || meta_of($caller, Evo::Class::Meta::new(class => $caller, gen => GEN));
  export_install_in($caller, $me, @args ? @args : '*');
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
    sub greet($self) : Public { say "I'm " . $self->name }
  }

  my $alex = My::Human::new(gender => 'male');

  # default value "unnamed"
  say $alex->name;

  # fluent design
  $alex->name('Alex')->age(18);
  say $alex->name, ': ', $alex->age;

  # method
  $alex->greet;

  ## ------------ protecting you from errors, uncomment to test
  ## will die, gender is required
  #My::Human::new();

  ## will die, age must be >= 18
  #My::Human::new(age => 17, gender => 'male');
  #My::Human::new()->age(17, gender => 'male');

  # --------- code reuse
  {

    package My::Developer;
    use Evo -Class;
    with 'My::Human'; # extends 'My::Human'; implements 'My::Human';

    has lang => 'Perl';

    sub show($self) : Public {
      $self->greet();
      say "I like ", $self->lang;
    }


  }

  my $dev = My::Developer::new(gender => 'male');
  $dev->show;


=head1 DESCRIPTION

=head2 Mixins programming

A new promising inject-code programming concepts based on mixins. Documentation will be available if someone will be willing to help write it.

=head2 Why not OO and Moose like?

The most problems with Moose like modules is with initialization. Let's take a look:

  package My::Moose;
  use Moose;
  has foo => is =>'rw';

  package main;
  my $obj = My::Moose->new(fo => 3);
  print $obj->foo;

As you can see, we passed C<fo> instead of C<foo>, and Moose silently ignored it. You should write a huge amout of extra tests to pervent such errors.

Also traditional OO programming suffers the fragile base class problems (use Google). To solve it, injection based C<Evo::Class> introduces flexible roles L<Evo::Role>. 


=head1 Usage

=head2 creating an object

  package My::Class;
  use Evo -Class;
  has 'simple';

You don't need to call something like C<__PACKAGE__-E<gt>meta-E<gt>make_immutable> unlike in L<Moose>, Evo objects are fast enough by design.

=head2 new

B<important!!!>
Because Evo objects reuse code horizontal, there's no need to pass the class string to every invocation of C<new> (or C<Evo::Class::Out/"init">). So instead of C<My::Class-E<gt>new> use C<My::Class::new>


  my $foo = My::Class::new(simple => 1);
  my $foo2 = My::Class::new();

We're protected from common mistakes, because constructor won't accept unknown attributes

  my $foo = My::Class::new(SiMple => 1);

=head2 Storage

The big advantage of Evo object that it's not tied with implementation. The default uses hashes L<Evo::Class::Hash>, but you can easily switch for example to L<Evo::Class::Out> and use any other refs

=head2 Declaring attribute 

  package My::Foo;
  use Evo '-Class *';

  has 'simple';
  has 'short' => 'value';
  has 'foo' => default => 'value', is => 'rw', check => sub {1};

=head3 Syntax

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

  has ref => sub(%build_args) { {} };
  has foo => default => sub(%build_args) { [] };

This is a good way to init some attribute that should always exists. Arguments, passed to C<new> or C<init>  will be passed to the function without object itself (because there are no object yet). If you're expecting another behaviour, check L</lazy>

=head4 lazy

Like default, but will be filled at the first invocation, not in constructor, and an instance will be passed as the argument

  # pay attention, an instance is passed
  has foo => lazy => sub($self) { [] };

=head4 required

Attributes with this options are required

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

  my $foo = My::Foo::new(big => 11);

  $foo->big(9);    # will die
  my $bar = My::Foo::new(big => 9);    # will die


=head1 CODE REUSE

Method should be marked with C<:Public> if you want to reuse them; Attributes are all public;

=head2 Overriding

Evo protects you from method clashing. But if you want to override method or fix clashing, use L</has_overriden> function or C<:Override> attribute

    package My::Peter;
    use Evo -Class;
    with 'My::Human';

    has_overriden name => 'peter';
    sub greet : Overriden { }


This differs from traditional OO style. With compoment programming, you should reuse code via L<Evo::Class::Role> or just organize classes with independed pieces of code like "mixing". So, try to override less

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

    sub greet($self) : Public {
      say "My name is ", $self->name, " and I'm happy!";
    }

    package My::Class;
    use Evo -Class;

    has name => 'alex';

    #extends 'My::Role::Happy';
    #implements 'My::Role::Happy';
    with 'My::Role::Happy';

  }

  My::Class::new()->greet();



C<My::Role::Happy> requires C<name> in derivered class. We could install shared code with C<extends> and then check implemantation with C<implements>. Or just use C<with> wich does both.

You may want to use C<extends> and C<implements> separately to resolve circular requirements, for example

=head1 CODE ATTRIBUTES

  sub foo : Override { 'OVERRIDEN'; }

Mark name as overriden. See L<Evo::Role/"Overriding methods">

=cut
