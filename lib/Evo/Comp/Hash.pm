package Evo::Comp::Hash;
use Evo '/::Gen::Hash GEN; -Role ROLE_EXPORTER; /::Meta; -Export::Core *';

use Evo '-Attr *';
export_proxy '-Attr', 'MODIFY_CODE_ATTRIBUTES';

my $META = Evo::Comp::Meta::new(gen => GEN, rex => ROLE_EXPORTER);

sub import ($me, @args) {
  export_install_in(scalar caller, $me, @args ? @args : '*');
  attr_install_code_handler_in(scalar caller);
}

export_gen new => sub($class) { $META->compile_builder($class); };

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

attr_register_code_handler \&_attr_handler;

1;

=head1 DESCRIPTION

Hash based driver for L<Evo::Comp>

=cut
