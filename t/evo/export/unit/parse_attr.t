package main;
use Evo '-Export';
use Test::More;

*parse = *Evo::Export::_parse_attr;

is_deeply [parse('Export')],         ['Export', undef];
is_deeply [parse('Export()')],       ['Export', undef];
is_deeply [parse('Export(w33)')],    ['Export', 'w33'];
is_deeply [parse('Export( w33  )')], ['Export', 'w33'];

done_testing;
