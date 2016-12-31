package Test::Evo::Helpers;
use Evo '-Export *';

sub test_memory ($count, $limit, $code) : Export {
  require Memory::Stats;
  my $stats = Memory::Stats->new;
  {
    $stats->start;
    $code->() for 1 .. $count;
  }
  $stats->stop;
  my $consumed = $stats->usage;
  die "consumed $consumed bytes, threshold is: $limit" if $limit && $stats->usage > $limit;
  $consumed;
}

1;
