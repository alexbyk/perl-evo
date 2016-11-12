package Evo::Promise::AE;
use Evo '-Class; -Export *';

BEGIN {
  eval { require AE; 1 } or die "Install AnyEvent to use this module";
}
with '-Promise::Role';

sub postpone ($me, $sub) {
  &AE::postpone($sub);
}

foreach my $fn (qw(promise deferred resolve reject race all)) {
  export_code $fn , sub {
    __PACKAGE__->$fn(@_);
  };
}

1;

=head1 SYNOSIS

  use Evo '-Promise::AE *';

  my $cv = AE::cv;
  my $w;

  sub load_later($url) {
    my $d = deferred();
    $w = AE::timer(1, 0, sub { $d->resolve("HELLO: $url") });
    $d->promise;
  }

  load_later('http://alexbyk.com')->then(sub($v) { say $v })->finally(sub { $cv->send });

  $cv->recv;

=head1 DESCRIPTION

Promises/A+ for L<AE> - install L<AnyEvent> it to use this module.

See L<Evo::Promise::Mojo> for documentation (it's the same) and L<Mojo::Pua> for more real-world examples.

See also L<Evo::Promise::Role>, this class is based on it.

=cut
