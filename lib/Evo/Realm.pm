package Evo::Realm;
use Evo '-Export *', '-Lib *';
use Evo::Util;
use Carp 'croak';
use Scalar::Util qw(refaddr blessed);


my %REALM;
sub REALM_DATA { \%REALM }

export_gen realm_lord => sub($key) {
  sub {
    return $REALM{$key} if exists $REALM{$key};
    $_[0] ? $_[0] : croak qq{not in realm of "$key"};
  };
};

export_gen realm => sub($key) {
  sub {
    my ($obj, $fn) = (shift, pop);
    local $REALM{$key} = $obj;
    $fn->(@_);
  };
};

1;
