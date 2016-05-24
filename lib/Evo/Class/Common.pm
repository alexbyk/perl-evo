package Evo::Class::Common;
use Evo '-Export *; -Attr *; -Class::Util parse_style';
use Evo 'List::Util first; Carp croak; Module::Load load';
use Evo::Lib::Bare;


export_gen has => sub($class) {
  sub ($name, @opts) {
    meta_of($class)->install_attr($name, @opts);
  };
};

export_gen reg_attr => sub($class) {
  sub ($name, @opts) {
    meta_of($class)->reg_attr($name, parse_style @opts);
  };
};

export_gen has_overriden => sub($class) {
  sub ($name, @opts) {
    meta_of($class)->mark_overriden($name)->install_attr($name, @opts);
  };
};

export_gen requires => sub($class) {
  sub (@names) { meta_of($class)->reg_requirement($_) for @names; };
};

export_gen extends => sub($class) {
  sub(@parents) {
    my $meta = meta_of($class);
    foreach my $par (@parents) {
      $par = Evo::Lib::Bare::resolve_package($class, $par);
      load $par;
      $meta->extend_with(meta_of($par));
    }
  };
};

export_gen implements => sub($class) {

  sub (@interfaces) {
    my $meta = meta_of($class);
    foreach my $inter (@interfaces) {
      $inter = Evo::Lib::Bare::resolve_package($class, $inter);
      load $inter;
      croak "$inter isn't a Class" unless my $inter_meta = meta_of($inter);
      $meta->check_implementation($inter_meta);
    }
  };
};

export_gen with => sub($class) {

  sub (@parents) {
    my $meta = meta_of($class);
    foreach my $par (@parents) {
      $par = Evo::Lib::Bare::resolve_package($class, $par);
      load $par;
      croak "$par isn't a Class" unless my $par_meta = meta_of($par);
      $meta->with($par_meta);
    }
  };
};

sub _attr_handler ($class, $code, @attrs) {
  if (grep { $_ eq 'Overriden' } @attrs) {
    meta_of($class)->mark_overriden($_) for Evo::Lib::Bare::find_subnames($class, $code);
  }
  if (grep { $_ eq 'Public' } @attrs) {
    meta_of($class)->reg_method($_, code => $code)
      for Evo::Lib::Bare::find_subnames($class, $code);
  }

  grep {
    my $cur = $_;
    !first { $cur eq $_ } qw(Public Overriden)
  } @attrs;
}

attr_handler \&_attr_handler;


my %METAS;

# get or set once
sub meta_of ($class, $meta = undef) : Export {
  return $METAS{$class} if !$meta;
  croak "$class already has META" if $METAS{$class};
  $METAS{$class} = $meta;
}

export_gen new => sub($class) { meta_of($class)->compile_builder; };
1;
