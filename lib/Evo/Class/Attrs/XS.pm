package Evo::Class::Attrs::XS;
use Evo 'XSLoader';

use Evo '-Export; Carp croak confess';
use constant {ECA_SIMPLE => 0, ECA_DEFAULT => 1, ECA_DEFAULT_CODE => 2, ECA_REQUIRED => 3,
  ECA_LAZY => 4,};

export qw(
  ECA_SIMPLE ECA_DEFAULT ECA_DEFAULT_CODE ECA_REQUIRED ECA_LAZY
);

# VERSION

# to be able to run with and without dzil
my $version = eval '$VERSION';    ## no critic
$version ? XSLoader::load("Evo::Class::Attrs::XS", $version) : XSLoader::load("Evo::Class::Attrs::XS");

sub new { bless [], shift }

sub gen_attr ($self, $name, $type, $value, $check, $ro, $inject) {
  my $slot_ref = $self->_reg_attr($name, $type, $value, $check, $ro, $inject);
  $self->_gen_attr($slot_ref);
}


1;

# ABSTRACT: XS implementation of attributes and "new" method generator
