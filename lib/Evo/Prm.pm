package Evo::Prm;
use Evo '-Export *; Carp croak; -Promise promise_resolve';

our $PRM;

export_proxy 'Evo::Promise', '*';

sub prm($fn) : prototype(&) : Export {
  croak "Broken flow" if $PRM;
  local $PRM = promise_resolve(undef);
  $fn->();
  $PRM;
}

sub then : prototype(&) : Export {
  croak "Broken flow" unless $PRM;
  $PRM = $PRM->then(@_);
}

sub catch : prototype(&) : Export {
  croak "Broken flow" unless $PRM;
  $PRM = $PRM->then(undef, @_);
}

sub spread : prototype(&) : Export {
  croak "Broken flow" unless $PRM;
  $PRM = $PRM->spread(@_);
}

1;

=head1 SYNOPSYS

  use Evo '-Prm *; -Loop *';

  sub download($url) { uc $url }

  my $p = prm {

    then {
      promise_all me => download('http://alexbyk.com'), g => download('http://google.com');
    };

    spread sub(%results) {
      say $results{me};
      say $results{g};
      return $results{me} . $results{g};
    };

    catch sub($e) { };
  };

  $p->then(sub($v) { say $v });

  loop_start;

=head1 DESCRIPTION

This module provides experimental pure syntax to L<Evo::Promise>

=cut
