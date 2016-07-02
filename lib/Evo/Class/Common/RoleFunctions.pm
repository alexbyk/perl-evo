package Evo::Class::Common::RoleFunctions;
use Evo '-Export *, -import; -Internal::Util';
use Evo 'Carp croak';
use Evo::Class::Meta;

no warnings 'once';

sub META ($me, $dest) : ExportGen {
  sub { Evo::Class::Meta->find_or_croak($dest); };
}

sub requires ($me, $dest) : ExportGen {

  sub (@names) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    $meta->reg_requirement($_) for @names;
  };
}

sub implements ($me, $dest) : ExportGen {

  sub (@interfaces) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $inter (@interfaces) {
      $inter = Evo::Internal::Util::resolve_package($dest, $inter);
      my $inter_meta = $meta->find_or_croak($inter);
      $meta->check_implementation($inter);
    }
  };
}


sub Over ($dest, $code, $name) : Attr {
  Evo::Class::Meta->find_or_croak($dest)->mark_as_overridden($name);
}

1;
