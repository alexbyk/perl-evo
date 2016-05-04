use Evo;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Evo 'MyLib *';
use Evo 'MyLibAll';    # uses import_all

is foo(),   'FOO';
is fooa1(), 'FOO';
is fooa2(), 'FOO';

ok !main->can('bar');
is bara1(), 'BAR';
is bara2(), 'BAR';

is noname(), 'noname';

is default_sub(), 'DEFAULT';

done_testing;
