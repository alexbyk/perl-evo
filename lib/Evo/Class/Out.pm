package Evo::Class::Out;
use Evo '-Export export_proxy; -Class::Gen::Out';

export_proxy 'Evo::Class::Common::RoleFunctions',    '*';
export_proxy 'Evo::Class::Common::StorageFunctions', '*';

sub init ($me, $dest) : ExportGen {
  $me->class_of_gen->find_or_croak($dest)->gen_init;
}

my $GEN_IMPL
  = eval { require Evo::Class::Gen::Out::XS; 1 }
  ? 'Evo::Class::Gen::Out::XS'
  : 'Evo::Class::Gen::Out';

sub class_of_gen($self) {$GEN_IMPL}

# don't subclass this or there will be too many abstractions
sub import ($me, @list) {
  my $caller = caller;
  Evo::Class::Meta->register($caller);
  my $gen = $me->class_of_gen->register($caller);
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
}

no warnings 'once';
*import = *Evo::Class::Common::Util::register_and_import;

1;

=head2 SYNOPSYS

  package main;
  use Evo;

  {

    package My::Out;
    use Evo -Class::Out;

    sub new ($class, %opts) {
      init($class, [], %opts);
    }

    has 'foo';
  }

  my $obj = My::Out->new(foo => 33);
  say $obj;         # ...ARRAY...
  say $obj->foo;    # 33

=head2 DESCRIPTION

Like L<Evo::Class>, but uses outside storage. So any reference can became a class instance
Instead of C<new>, it provides C<init>. You can define C<new> by yourself


=cut
