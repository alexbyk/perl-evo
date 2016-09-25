package Evo::Lib::XS;
use Evo 'XSLoader; -Export';

# VERSION

# to be able to run with and without dzil
my $version = eval '$VERSION';    ## no critic
$version ? XSLoader::load(__PACKAGE__, $version) : XSLoader::load(__PACKAGE__);

export('try');

1;
