use Evo;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyLib '*';

is foo(),   'FOO';
is fooa1(), 'FOO';
is fooa2(), 'FOO';

ok !main->can('bar');
is bara1(), 'BAR';
is bara2(), 'BAR';

is noname(), 'noname';

done_testing;
