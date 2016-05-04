package Evo::Class::Hash;
use Evo '/::Gen::Hash GEN; -Role ROLE_EXPORTER; /::Meta; -Attr *';
use Evo '-Export *, -import, import_all:import';

my $META = Evo::Class::Meta::new(gen => GEN, rex => ROLE_EXPORTER);

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

attr_handler \&_attr_handler;

1;

=head1 DESCRIPTION

Hash based driver for L<Evo::Class>

=cut
