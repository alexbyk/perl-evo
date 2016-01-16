use Evo 'Test::More; -Io';

my $io = Evo::Io::new();

plan skip_all => 'Looks like a ro system' unless open $io, '>', undef;

ok $io->io_non_blocking(1)->io_non_blocking;

done_testing;
