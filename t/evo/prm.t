use Evo 'Test::More; -Prm *; -Loop *; -Promise::Util *';

my $promise = prm {};


my $p = prm {
  then {'VAL'};
  then sub($v) { [$v, 'other'] };
  spread sub(@vals) { join ';', @vals; };
};
my $pe = prm {
  then { die "MyE\n"; };
  catch sub($e) {"GOT:$e"}
};

is $p->state,  PENDING;
is $pe->state, PENDING;

loop_start;
ok is_fulfilled_with 'VAL;other', $p;
ok is_fulfilled_with "GOT:MyE\n", $pe;

done_testing;
