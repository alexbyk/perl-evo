use Evo '-Class::Util parse_style';
use Test::More;
use Test::Fatal;

use constant EXTRA_FEATURES => ['is', 'type'];


ERRORS: {

  # required + default doesn't make sense
  like exception { parse_style(required => 1, default => 'foo') }, qr/default.+required.+$0/;


  # required or lazy should be either scalar or coderef
  like exception { parse_style(default => {}) }, qr/default.+$0/;
  like exception { parse_style(lazy    => {}) }, qr/lazy.+$0/;

  # extra known
  like exception { parse_style(un1 => 1, un2 => 2) }, qr/unknown.+un1.+un2.+$0/;

}


is_deeply { parse_style() }, {};

# perl6 && mojo style for default
is_deeply { parse_style('FOO') }, {default => 'FOO'};

# perl6 style
is_deeply { parse_style('FOO', is => 'rw') }, {is => 'rw', default => 'FOO'};

#  moose style
is_deeply { parse_style(is => 'rw', default => 'FOO') }, {is => 'rw', default => 'FOO'};

# required
is_deeply { parse_style(is => 'rw', required => 1) }, {is => 'rw', required => 1};


# all
my $t = sub {1};
is_deeply {
  parse_style(is => 'rw', check => $t, required => 1, lazy => 1,)
}, {is => 'rw', required => 1, lazy => 1, check => $t};

is_deeply {
  parse_style(is => 'rw', check => $t, default => 1, lazy => 1)
}, {is => 'rw', default => 1, check => $t, lazy => 1};

done_testing;
