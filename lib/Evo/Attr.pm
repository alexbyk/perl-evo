package Evo::Attr;
use Evo::Attr::Class;
use Evo '-Export::Core *';    # because Evo::Export relies on me

*DEFAULT = *Evo::Attr::Class::DEFAULT;

my $MODIFY_CODE_ATTRIBUTES = sub { DEFAULT()->run_code_handlers(@_); };

export_gen attr_handler => sub($provider) {
  sub($handler) {
    my $EXP  = Evo::Export::Class::DEFAULT;
    my $ATTR = Evo::Attr::Class::DEFAULT;

    # register handler
    $ATTR->register_code_handler($provider, $handler);

    # add MODIFY_CODE_ATTRIBUTES for provider's export list
    $EXP->add_gen(
      $provider,
      'MODIFY_CODE_ATTRIBUTES',
      sub($dpkg) {
        $ATTR->install_code_handler_in($dpkg, $provider);
        $MODIFY_CODE_ATTRIBUTES;
      }
    );

  };
};


1;


=head1 SYNOPSYS

  # Foo.pm
  package Foo;
  use Evo '-Attr attr_handler; -Export import';

  attr_handler(
    sub ($pkg, $code, @attrs) {
      my @found     = grep {/^Foo/} @attrs;
      my @remaining = grep { !/^Foo/ } @attrs;
      say "found in $pkg ($code): " . join ', ', @found if @found;
      @remaining;
    }
  );


  # test.pl
  use Evo 'Foo *';
  sub foo : Foo {...}

=head1 DESCRIPTION

Provides a nice way to use attributes without limitations.

=head1 USAGE

Package that provides attribute should call L</attr_handler> with a handler as a first argument. That handler should examine attributes, and return unknown for other handlers.

Provider should also import L<Evo::Export/import> to be able to export C<MODIFY_CODE_ATTRIBUTES> into the package, that uses attributes.

This approach allow mix different attributes without patching C<UNIVERSAL>.

  package Bar;

  use Evo '-Loaded; -Attr attr_handler; -Export import';

  attr_handler(
    sub ($pkg, $code, @attrs) {
      my @found     = grep {/^Bar/} @attrs;
      my @remaining = grep { !/^Bar/ } @attrs;
      say "found in $pkg ($code): " . join ', ', @found if @found;
      @remaining;
    }
  );

  # test2.pl
  use Evo 'Foo *; Bar *';

  sub multi : Foo : Bar(args) {...}

=head2 attr_handler

This method should be called only once. In fact, it adds C<MODIFY_CODE_ATTRIBUTES> to export list and call internal methods that register handler.

1;
