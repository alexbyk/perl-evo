package main;
use Evo '-Class::Gen::XS; Benchmark cmpthese';

{

  package My::Evo;
  use Evo -Class, -Loaded;
  has 'sm';
  has 'df', default => sub {'DEF'};
  has 'lz', lazy    => sub {'LAZY'};

  package My::Simple::Evo;
  use Evo -Class, -Loaded;
  has($_) for qw(foo bar baz);

  package My::Simple::Mojo;
  use Mojo::Base -base;
  has($_) for qw(foo bar baz);

}

## no critic
do {
  my $code = qq|
  package My::Simple::$_;
  use $_;
  has(\$_, is => 'rw') for qw(foo bar baz);
  __PACKAGE__->meta->make_immutable;

  package My::$_;
  use $_;
  use ${_}X::StrictConstructor;
  has 'sm', is => 'rw';
  has 'df', is => 'rw', default => sub {'DEF'};
  has 'lz', is => 'rw', default => sub {'LAZY'}, lazy => 1;
  __PACKAGE__->meta->make_immutable;|;

  eval $code;
  die $@ if $@;
  }
  for qw(Moo Mouse Moose);

# new
say "->new(...) - benchmark object initialization with 3 values";
my %hash = map {
  my $class = "My::Simple::$_";
  $_ => sub { my $obj = $class->new(foo => 1, bar => 2, baz => 3); };
} qw(Evo Moo Mouse Mojo Moose);
cmpthese 1_000_000, \%hash;

# accessor
say "\n\n";
say "->foo('SIMPLE'); ->foo; Simple accessors";
%hash = map {
  my $obj = "My::Simple::$_"->new();
  $_ => sub { $obj->foo('SIMPLE'); $obj->foo eq 'SIMPLE' or die "$obj"; };
} qw(Evo Moo Mouse Moose Mojo);
cmpthese 5_000_000, \%hash;


# roundtrip
say "\n\n";
say "Roundtrip";
%hash = map {
  my $class = "My::$_";
  $_ => sub {
    my $obj = $class->new();
    $obj->sm('SIMPLE');
    die "$class" unless ($obj->df . $obj->sm . $obj->lz) eq 'DEFSIMPLELAZY';
  };
} qw(Evo Moo Mouse Moose);    # Mojo doesn't take a part because doesn't support default
cmpthese 1_000_000, \%hash;
