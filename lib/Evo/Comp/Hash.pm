package Evo::Comp::Hash;
use Evo '-Export *';
use Evo::Lib 'monkey_patch';
use Evo '::Gen::Hash GEN; ::Role ROLE_EXPORTER';
use Evo '::Meta';

my $META = Evo::Comp::Meta::new(gen => GEN, rex => ROLE_EXPORTER);

export_gen new => sub($class) { $META->compile_builder($class); };

export_gen has => sub($class) {
  sub { $META->install_attr($class, @_); };
};

export_gen with => sub($class) {
  sub { $META->install_roles($class, @_); };
};


1;

=head1 DESCRIPTION

Hash based driver for L<Evo::Comp>

=cut
