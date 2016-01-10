package main;
use Evo;
use Test::More;
use Test::Fatal;

{

  package My::Comp;
  use Evo '-Comp *';
  with 'Evo::Ee';

  sub ee_events {qw(e1 e2)}
}

EE_CHECK: {
  my $obj = My::Comp::new();
  like exception { $obj->ee_check('bad'); }, qr/Not recognized event "bad"/;
  is $obj->ee_check('e1'), $obj;
}


BAD_EVENT: {
  my $obj = My::Comp::new();
  like exception {
    $obj->on('bad', sub { });
  }, qr/Not recognized event "bad"/;

  like exception {
    $obj->ee_remove('bad', sub { });
  }, qr/Not recognized event "bad"/;

}

my ($F1, $F1a, $F2) = (sub {1}, sub {2}, sub {3});
ADD_REMOVE: {
  my $obj = My::Comp::new();
  is_deeply $obj->on(e1 => $F1)->on(e1 => $F1)->on(e1 => $F1a)->on(e2 => $F2)->ee_data,
    [[e1 => $F1], [e1 => $F1], [e1 => $F1a], [e2 => $F2]];

  # remove listener from wrong event
  is_deeply $obj->ee_remove(e2 => $F1)->ee_remove(e1 => $F2)->ee_data,
    [[e1 => $F1], [e1 => $F1], [e1 => $F1a], [e2 => $F2]];

  # remove first
  is_deeply $obj->ee_remove(e1 => $F1)->ee_data, [[e1 => $F1], [e1 => $F1a], [e2 => $F2]];

  # last
  is_deeply $obj->ee_remove(e2 => $F2)->ee_data, [[e1 => $F1], [e1 => $F1a]];

  is_deeply $obj->ee_remove(e1 => $F1a)->ee_data, [[e1 => $F1]];
  is_deeply $obj->ee_remove(e1 => $F1)->ee_data, [];
}


LISTENERS: {
  my $obj = My::Comp::new();
  $obj->on(e1 => $F1)->on(e1 => $F1)->on(e1 => $F1a)->on(e2 => $F2);
  is_deeply [$obj->ee_listeners('e1')], [$F1, $F1, $F1a];
  is_deeply [$obj->ee_listeners('e2')], [$F2];
}

EMIT: {
  my $obj = My::Comp::new();
  my @got = @_;
  is $obj->on(e1 => sub { @got = @_ })->emit(e1 => 1, 2), 1;
  is $obj->emit('e2'), 0;
  is_deeply \@got, [$obj, 1, 2];
}

done_testing;
