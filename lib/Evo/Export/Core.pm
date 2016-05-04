package Evo::Export::Core;
use Evo '-Export::Class; Carp croak; -Lib::Bare';

# + export export_gen export_anon export_proxy export_requires export_hooks
my @EXPORT = qw(export_install_in import import_all);
Evo::Export::Class::DEFAULT->add_sub(__PACKAGE__, $_) for @EXPORT;

sub import { export_install_in(scalar caller, @_); }

sub import_all ($me, @args) {
  export_install_in(scalar caller, $me, @args ? @args : '*');
}


sub export_install_in ($dst, $src, @list) {
  Evo::Export::Class::DEFAULT->install($src, $dst, @list) if @list;
}

sub _add_gen ($name, $gen) {
  Evo::Export::Class::DEFAULT->add_gen(__PACKAGE__, $name, $gen);
}

_add_gen export_gen => sub($dst) {
  sub ($name, $gen) {
    Evo::Export::Class::DEFAULT->add_gen($dst, $name, $gen);
    }
};

_add_gen export_anon => sub($dst) {
  sub {
    my ($name, $fn) = @_;
    Evo::Export::Class::DEFAULT->add_gen($dst, $name, sub {$fn});
  };
};

_add_gen export => sub($dst) {
  sub { Evo::Export::Class::DEFAULT->add_sub($dst, $_) for @_ }
};

_add_gen export_proxy => sub($dst) {
  sub ($epkg, @list) {
    Evo::Export::Class::DEFAULT->proxy($dst, $epkg, @list);
    }
};


1;
