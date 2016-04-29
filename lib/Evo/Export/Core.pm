package Evo::Export::Core;
use Evo '-Export::Exporter; Carp croak; -Lib::Bare';

# + export export_gen export_anon export_proxy export_requires export_hooks
my @EXPORT = qw( export_install_in MODIFY_CODE_ATTRIBUTES);
Evo::Export::Exporter::DEFAULT->add_sub(__PACKAGE__, $_) for @EXPORT;

sub import { export_install_in(scalar caller, @_); }

sub export_install_in($dst, $src, @list) { Evo::Export::Exporter::DEFAULT->install($src, $dst, @list) if @list; }

# pay attention: without provided name all aliases will be found by _find_subnames and exported
sub MODIFY_CODE_ATTRIBUTES($pkg, $code, @attrs) {
  my (@bad, @good);
  foreach my $attr (@attrs) {
    my ($attr_name, $val) = _parse_attr($attr);
    $attr_name eq 'Export' ? push @good, $val : push @bad, $attr;
  }
  return @bad if @bad;

  foreach my $name (@good) {
    my @names = $name ? ($name) : Evo::Lib::Bare::find_subnames($pkg, $code);
    Evo::Export::Exporter::DEFAULT->add_gen($pkg, $_, sub {$code}) for @names;
  }

  return;
}

sub _parse_attr($attr) {
  $attr =~ /(\w+) ( \( \s* (\w+) \s* \) )?/x;
  return ($1, $3);
}


sub _add_gen($name, $gen) { Evo::Export::Exporter::DEFAULT->add_gen(__PACKAGE__, $name, $gen); }

_add_gen export_gen => sub($dst) {
  sub($name, $gen) { Evo::Export::Exporter::DEFAULT->add_gen($dst, $name, $gen) }
};

_add_gen export_anon => sub($dst) {
  sub {
    my ($name, $fn) = @_;
    Evo::Export::Exporter::DEFAULT->add_gen($dst, $name, sub {$fn});
  };
};

_add_gen export => sub($dst) {
  sub { Evo::Export::Exporter::DEFAULT->add_sub($dst, $_) for @_ }
};

_add_gen export_proxy => sub($dst) {
  sub($epkg,@list) { Evo::Export::Exporter::DEFAULT->proxy($dst, $epkg, @list); }
};

1;
