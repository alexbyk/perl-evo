package Evo::Class::Common::GenBase;
use Evo '-Class::Common::Util; -Internal::Util; Carp croak';

my $KEY = 'EVO_CLASS_GEN';

sub register ($me, $package) {
  my $self;
  if ($self = Evo::Internal::Util::pkg_stash($package, $KEY)) {
    croak "$package already has $self, can't register $me" if ref($self) ne $me;
    return $self;
  }
  $self = $me->new($package);
  Evo::Internal::Util::pkg_stash($package, $KEY, $self);
  return $self;
}

sub find_or_croak ($self, $package) {
  Evo::Internal::Util::pkg_stash($package, 'EVO_CLASS_GEN') or croak "$package isn't Evo::Class";
}


1;
