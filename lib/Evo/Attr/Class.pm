package Evo::Attr::Class;
use Evo 'Carp croak';

sub new { bless {handlers => {}, providers => {}}, __PACKAGE__ }
use constant DEFAULT => new();
sub handlers  { shift->{handlers} }
sub providers { shift->{providers} }

sub register_code_handler ($self, $provider, $handler) {
  croak qq/Provider "$provider" has been already registered/ if $self->providers->{$provider};
  $self->providers->{$provider} = $handler;
}

sub install_code_handler_in ($self, $dest, $provider) {
  croak qq/Provider "$provider" hasn't been registered/
    unless my $handler = $self->providers->{$provider};
  push $self->handlers->{$dest}->@*, $self->providers->{$provider};
}

sub run_code_handlers ($self, $dest, $code, @attrs) {
  return @attrs unless my $list = $self->handlers->{$dest};
  @attrs = $_->($dest, $code, @attrs) for @$list;
  @attrs;
}


1;
