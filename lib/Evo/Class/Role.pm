package Evo::Class::Role;
use Evo '-Export export_proxy; -Class::Meta';

export_proxy 'Evo::Class::Common::RoleFunctions', '*';

sub has ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    @opts = $meta->parse_attr(@opts);
    $meta->reg_attr($name, @opts);
  };
}

sub has_over ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    @opts = $meta->parse_attr(@opts);
    $meta->reg_attr_over($name, @opts);
  };
}


# don't subclass this or there will be too many abstractions
sub import ($me, @list) {
  my $caller = caller;
  Evo::Export->install_in($caller, $me, @list ? @list : '*');
  Evo::Class::Meta->register($caller);
}

sub extends ($me, $dest) : ExportGen {
  sub(@parents) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $par (@parents) {
      $par = Evo::Internal::Util::resolve_package($dest, $par);
      $meta->extend_with($par);
    }
  };
}


sub with ($me, $dest) : ExportGen {

  sub (@parents) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $par (@parents) {
      $par = Evo::Internal::Util::resolve_package($dest, $par);
      $meta->extend_with($par);
      $meta->check_implementation($par);
    }
  };
}

1;

=head1 DESCRIPTION

Roles share attributes and methods, but can't build objects

=cut
