package Evo::Class::Role;
use Evo '-Class::Meta; -Class::Util parse_style; Carp croak; -Class::Common meta_of';
use Evo '-Export *, -import';

export_proxy '-Class::Common', qw(MODIFY_CODE_ATTRIBUTES requires reg_attr:has);

sub new : Export {
  my $class = __PACKAGE__;
  croak qq/You can't directly create an instance of a role "$class"/;
}

sub import ($me, @args) {
  my $caller = caller;
  meta_of($caller) || meta_of($caller, Evo::Class::Meta::new(class => $caller));
  export_install_in($caller, $me, @args ? @args : '*');
}

1;

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    # role
    package My::Role;
    use Evo '-Class::Role *; -Loaded';

    has myattr => 'VAL';
    sub to_lc($self) : Public { lc $self->myattr }


    # class
    package My::Class;
    use Evo '-Class *';

    with 'My::Role';

  }


  my $obj = My::Class::new();
  say $obj->to_lc;    # value

  {
    # just check implementation
    package My::BadClass;
    use Evo '-Class *';

    # will die
    implements 'My::Role';
  }

=head1 DESCRIPTION

Role is just like classes except you can only reuse it. You can't create an instance of the role. If you need to reuse a code without "should be overriden by subclass" hacks - role is just what you expecting

Also can be used as "interaces"

=cut

