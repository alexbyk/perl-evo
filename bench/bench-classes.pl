package main;
use Evo;
use Test::Evo::Benchmark;
use Benchmark 'cmpthese';
use Evo::Class::Gen::XS;

{

  package My::Evo;
  use Evo -Class, -Loaded;
  has 'sm', is => 'rw';
  has 'df', is => 'rw', default => sub {'DEF'};
  has 'lz', is => 'rw', lazy => sub {'LAZY'};
  die META->gen . ' isnt XS' unless ref(META->gen) eq 'Evo::Class::Gen::XS';

  package My::Mojo;
  use Mojo::Base -base;
  has 'sm';
  has 'df', sub {'DEF'};
  has 'lz', sub {'LAZY'};

}

## no critic
do {
  my $code = qq|
  package My::$_;
  use $_;
  use ${_}X::StrictConstructor;
  has 'sm', is => 'rw';
  has 'df', is => 'rw', default => sub {'DEF'};
  has 'lz', is => 'rw', default => sub {'LAZY'}, lazy => 1;
  __PACKAGE__->meta->make_immutable;

  |;

  eval $code;
  die $@ if $@;
  }
  for qw(Moo Mouse Moose);

say "----------\n\n";
say "Simple accessors";
my %hash = map {
  my $obj = "My::$_"->new();
  $_ => sub { $obj->sm('SIMPLE'); $obj->sm eq 'SIMPLE' or die "$obj"; };
} qw(Evo Moo Mouse Moose Mojo);

cmpthese 5_000_000, \%hash;

say "----------\n\n";
say "Roundtip";
%hash = map {
  my $class = "My::$_";
  $class => sub {
    my $obj = $class->new();
    $obj->sm('SIMPLE');
    my $all = $obj->df . $obj->sm . $obj->lz;
    die "$class - $all" unless $all eq 'DEFSIMPLELAZY';
  };
} qw(Evo Moo Mouse Mojo Moose);


cmpthese 1_000_000, \%hash;
