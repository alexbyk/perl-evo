use Evo 'Test::More; FindBin; -Lib::Bare';
use lib "$FindBin::Bin/lib";

use Evo 'MyLib *';
use Evo 'MyLibAll';    # uses import_all

is foo(), 'FOO';
my ($pkg, $name) = Evo::Lib::Bare::code2names(\&foo);
is $pkg, 'MyLib';

is fooa1(), 'FOO';

ok !main->can('bar');
is bara1(), 'BAR';
is bara2(), 'BAR';

is noname(), 'noname';

is default_sub(), 'DEFAULT';

done_testing;
