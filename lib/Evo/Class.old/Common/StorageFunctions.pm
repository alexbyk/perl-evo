package Evo::Class::Common::StorageFunctions;
use Evo '-Export *, -import; -Internal::Util';
use Evo 'Carp croak';
use Evo::Class::Meta;

no warnings 'once';

sub attr_exists ($me, $dest) : ExportGen {
  $me->class_of_gen->find_or_croak($dest)->gen_attr_exists;
}

sub attr_delete ($me, $dest) : ExportGen {
  $me->class_of_gen->find_or_croak($dest)->gen_attr_delete;
}

sub has ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $meta   = Evo::Class::Meta->find_or_croak($dest);
    my %parsed = $meta->parse_attr(@opts);
    $meta->reg_attr($name, %parsed);

    my $gen = $me->class_of_gen->find_or_croak($dest);
    Evo::Internal::Util::monkey_patch $dest, $name, $gen->gen_attr($name, %parsed);
    $gen->sync_attrs($meta->attrs->%*);
  };
}

sub has_over ($me, $dest) : ExportGen {
  sub ($name, @opts) {
    my $meta   = Evo::Class::Meta->find_or_croak($dest);
    my %parsed = $meta->parse_attr(@opts);
    $meta->reg_attr_over($name, %parsed);

    my $gen = $me->class_of_gen->find_or_croak($dest);
    Evo::Internal::Util::monkey_patch_silent $dest, $name, $gen->gen_attr($name, %parsed);
    $gen->sync_attrs($meta->attrs->%*);
  };
}

sub _extend ($me, $dest, @parents) {
  my $meta = Evo::Class::Meta->find_or_croak($dest);
  my $gen  = $me->class_of_gen->find_or_croak($dest);
  my @names;
  foreach my $par (@parents) {
    $par = Evo::Internal::Util::resolve_package($dest, $par);
    push @names, $meta->extend_with($par);
  }
  $me->class_of_gen->find_or_croak($dest)->sync_attrs($meta->attrs->%*);
  foreach my $name (@names) {
    my $sub = $gen->gen_attr($name, $meta->attrs->{$name}->%*);
    my $fn = Evo::Internal::Util::monkey_patch $dest, $name, $sub;
  }
}

sub extends ($me, $dest) : ExportGen {
  sub(@parents) { _extend($me, $dest, @parents); };
}


sub with ($me, $dest) : ExportGen {

  sub (@parents) {
    my $meta = Evo::Class::Meta->find_or_croak($dest);
    foreach my $par (@parents) {
      $par = Evo::Internal::Util::resolve_package($dest, $par);
      _extend($me, $dest, $par);
      $meta->check_implementation($par);
    }
    $me->class_of_gen->find_or_croak($dest)->sync_attrs($meta->attrs->%*);
  };
}


1;
