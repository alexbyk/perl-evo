use Evo -Export::Exporter;
use Test::More;
use Test::Fatal;

my $obj = Evo::Export::Exporter::new();

like exception {
  $obj->request_gen('Bad', 'method', 'Dest')
},
  qr/Bad.+method.+$0/;

my $counter;
$obj->add_gen(
  'Lib', 'name',
  sub {
    is $_[0], 'Dest';
    $counter++;
    sub {$counter}
  }
);

my $fn = $obj->request_gen('Lib', 'name', 'Dest');
is $obj->data->{Lib}{name}{cache}{Dest}, $fn;
is $fn->(), 1;

done_testing;
