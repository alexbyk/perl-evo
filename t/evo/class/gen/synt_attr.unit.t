use Evo 'Test::More; Evo::Class::Gen; -Internal::Exception';


INDEXES: {
  my $gen = Evo::Class::Gen->new();
  $gen->gen_attr('a0');
  $gen->gen_attr('a1', ro => 1);
  is_deeply $gen->{attrs}, {a0 => {index => 0}, a1 => {index => 1, ro => 1}};

  # can't generate twice
  like exception { $gen->gen_attr('a0', required => 1) }, qr/Attribute "a0".+already/;

}


done_testing;
