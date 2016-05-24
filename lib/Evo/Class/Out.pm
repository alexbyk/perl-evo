package Evo::Class::Out;
use Evo '-Class::Gen::HUF GEN; -Class::Meta; -Class::Common meta_of';
use Evo '-Export *, -import';

export_proxy '-Class::Common', '*', '-meta_of', '-new', 'new:init';

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
