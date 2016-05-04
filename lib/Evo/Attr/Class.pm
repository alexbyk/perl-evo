package Evo::Attr::Class;
use Evo 'Carp croak; -Lib::Bare; List::Util first';

sub new { bless {handlers => {}, providers => {}}, __PACKAGE__ }
use constant DEFAULT => new();
sub handlers  { shift->{handlers} }
sub providers { shift->{providers} }

sub register_handler_of ($self, $provider, $handler) {
  croak qq/Provider "$provider" has been already registered/ if $self->providers->{$provider};
  $self->providers->{$provider} = $handler;
}

sub install_handler_in ($self, $dest, $provider) {
  croak qq/Provider "$provider" hasn't been registered/
    unless my $handler = $self->providers->{$provider};
  croak qq/Provider "$provider" has been already installed in "$dest"/
    if first { $_->{provider} eq $provider } $self->handlers->{$dest}->@*;

  push $self->handlers->{$dest}->@*,
    {handler => $self->providers->{$provider}, provider => $provider};
}

*debug = *Evo::Lib::Bare::debug;

sub run_handlers ($self, $dest, $code, @attrs) {
  debug("running handlers for $dest: (" . join(',', @attrs) . ')');
  return @attrs unless my $list = $self->handlers->{$dest};
  foreach my $slot (@$list) {
    my ($handler, $provider) = @$slot{qw(handler provider)};
    debug("invoking provider $provider");
    @attrs = $handler->($dest, $code, @attrs);
    debug('remaining: (' . join(',', @attrs) . ')');
  }
  @attrs;
}


1;
