package Evo::Class::Out;
use Evo '/::Gen::HUF GEN; -Role (); /::Meta; -Attr *';
use Evo '-Export *, -import, import_all:import';

my $META = Evo::Class::Meta::new(gen => GEN, rex => Evo::Role::Class::DEFAULT());

export_gen init => sub { $META->compile_builder(shift); };

export_gen has => sub($class) {
  sub { $META->install_attr($class, @_); };
};

export_gen with => sub($class) {
  sub { $META->install_roles($class, @_); };
};

export_gen overrides => sub($class) {
  sub { $META->mark_overriden($class, @_); };
};


# dont share this
sub _attr_handler ($class, $code, @attrs) {
  if (grep { $_ eq 'Override' } @attrs) {
    Evo::Lib::Bare::find_subnames($class, $code);
    $META->mark_overriden($class, Evo::Lib::Bare::find_subnames($class, $code));
  }
  return grep { $_ ne 'Override' } @attrs;
}

attr_handler \&_attr_handler;

1;

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    package My::Spy;
    use Evo '-Class::Out *';

    has 'foo', required => 1;
  }

  my $foo = My::Spy::init(sub { say "foo" }, foo => 'FOO');
  say $foo->foo;
  $foo->();

=head1 DESCRIPTION

Inside-out driver for L<Evo::Class> using L<Hash::Util::FieldHash>.
Makes possible to use any type of references as objects.

=head1 FEATURES

C<Evo::Class::Out> supports the same features as C<Evo::Class::Hash>, but is a little (20-30%, maybe twice), slower. But allow to use any references, that can be blessed, as objects

=head2 init

Instead of C<new>, it provides C<init>. So you can desing new, for example, as a clousure by yourself


=head1 EXAMPLE

In this example we created spy object, that logs all invocations. You can make the similar thing with overloading with the hash-class too, but this implementation has one advantage: it's a real C<codered> and C<reftype> returns C<CODE>, not C<HASH>.

  package main;
  use Evo;
  use Scalar::Util 'reftype';

  {

    package My::Spy;
    use Evo '-Class::Out *';
    use Scalar::Util 'weaken';

    has calls => sub { [] };
    has 'fn', required => 1;

    sub new {
      my $copy;
      $copy = my $sub = sub { push $copy->calls->@*, [@_]; $copy->fn->(@_); };
      weaken $copy;
      init($sub, @_);
      $sub;
    }
  }

  my $spy = My::Spy::new(fn => sub { local $, = ';'; say "hello", @_ });
  say reftype $spy;

  $spy->();
  $spy->(1);
  $spy->(1, 2);

  local $, = '';
  say "logged: ", $_->@* for $spy->calls->@*;
