package Evo::Loop::Role::Zone;
use Evo '-Comp::Role *';
use Evo::Lib '*';
use Carp 'croak';

has zone_data => sub { {} };

# calls callback with passed ws, and combines prev + passed for wcb
sub zone : Role {
  my ($self, $fn) = (shift, pop);
  my $data = $self->zone_data;
  local $data->{w} = ws_combine($data->{w} ? ($data->{w}) : (), @_);
  $fn->();
}

sub zone_cb($self, $cb) : Role {
  my $data = $self->zone_data;
  my $w    = $data->{w};

  # restore(or restore empty) in zcb
  $w and return sub {
    local $data->{w} = $w;
    $w->($cb)->(@_);
  };
  sub {
    local $data->{w};
    $cb->(@_);
  };
}


1;
