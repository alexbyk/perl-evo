package Evo::Comp;
use Evo '-Export *';
use Evo::Comp::Hash ();
export_proxy('Evo::Comp::Hash', '*');

sub import($me, @args) { export_install_in(scalar caller, $me, @args ? @args : '*') }

1;

=head1 SYNOPSYS


  package main;
  use Evo;

  {

    package My::Human;
    use Evo '-Comp *';

    has 'name' => 'unnamed';
    has 'gender', is => 'ro', required => 1;
    has age => check => sub($v) { $v >= 18 };
  }

  my $alex = My::Human::new(gender => 'male');

  # default value "unnamed"
  say $alex->name;

  # fluent design
  $alex->name('Alex')->age(18);
  say $alex->name, ': ', $alex->age;

  # will die, gender is required
  My::Human::new();

  # will die, age must be >= 18
  My::Human::new(age => 17, gender => 'male');
  My::Human::new()->age(17, gender => 'male');


=head1 DESCRIPTION

=head2 Component-oriented programming

A new promising component-oriented programming concepts. Documentation will be available if someone will be willing to help write it.

=head2 Why not OO and Moose like?

The most problems with Moose like modules is with initialization. Let's take a look:

  package My::Moose;
  use Moose;
  has foo => is =>'rw';

  package main;
  my $obj = My::Moose->new(fo => 3);
  print $obj->foo;

As you can see, we passed C<fo> instead of C<foo>, and Moose silently ignored it. You should write a huge amout of extra tests to pervent such errors.

Also traditional OO programming suffers the fragile base class problems (use Google). To solve it, component oriented C<Evo::Comp> introduces flexible component roles L<Evo::Role>. 

So I decided to write all the stuff and name it component oriented programming. More explanation will be written later


=head1 Usage

=head2 creating component

Describe a component, use need to import "*" to get it worked

  package My::Comp;
  use Evo '-Comp *';
  has 'simple';

You don't need to call something like C<__PACKAGE__-E<gt>meta-E<gt>make_immutable> unlike in L<Moose>, components are fast enough by design.

=head2 new

B<important!!!>
Because Components reuse code horizontal, there's no need to pass the class string to every invocation of C<new> (or C<Evo::Comp::Out/"init">). So instead of C<My::Class-E<gt>new> use C<My::Comp::new>


  my $foo = My::Comp::new(simple => 1);
  my $foo2 = My::Comp::new();

We're protected from common mistakes, because constructor won't accept unknown attributes

  my $foo = My::Comp::new(SiMple => 1);

=head2 Storage

The big advantage of component that it's not tied with implementation. The default uses hashes L<Evo::Comp::Hash>, but you can easily switch for example to L<Evo::Comp::Out> and use any other refs

=head2 Declaring attribute 

  package My::Foo;
  use Evo '-Comp *';

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

  # pay attention, no argument passed here
  has ref => sub() { {} };
  has foo => default => sub() { [] };

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
    use Evo '-Comp *';

    has big => check => sub($val) { $val > 10 ? 1 : (0, "not > 10"); };
  };

  my $foo = My::Foo::new(big => 11);

  $foo->big(9);    # will die
  my $bar = My::Foo::new(big => 9);    # will die


=head1 Code reuse

Instead of OO inheritance, wich suffers from fragile base class problem, C<Evo::Comp> provides L<Evo::Role>. This is a perfect choice for code reuse because of it's safety and flexibility. Look at L<Evo::Role> for more information

=head2 with

Load role and install all methods and attributes to the component. Supports L<Evo/"shortcuts">

    package Person;
    use Evo '-Comp *';

    with ':LoudHuman', ':Human';

Circular requirements can be solved by requiring roles in the single C<with>. See L<Evo::Role/"requires">

=head2 overrides

  override qw(foo bar);

Mark names as overriden. Use it before L</"with">. You can also use C<Override> attribute, wich is preferred. See L<Evo::Role/"Overriding methods">

=head1 CODE ATTRIBUTES

  sub foo : Override { 'OVERRIDEN'; }

Mark name as overriden. See L<Evo::Role/"Overriding methods">

=cut
