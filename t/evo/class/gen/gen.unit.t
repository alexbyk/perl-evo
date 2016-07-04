use Evo 'Test::More; Evo::Class::Gen; -Internal::Exception';

REG_ATTR: {
  my $gen = Evo::Class::Gen->new();
  $gen->reg_attr('a0', ro => 1);
  $gen->reg_attr('a1');
  is_deeply $gen->{attrs}, {a0 => {index => 0, ro => 1}, a1 => {index => 1}};

  # change attr but don't change an index
  $gen->reg_attr('a0', required => 1);
  is_deeply $gen->{attrs}, {a0 => {index => 0, required => 1}, a1 => {index => 1}};
}

INDEXES: {
  my $gen = Evo::Class::Gen->new();
  $gen->reg_attr('a0', ro => 1);
  is_deeply $gen->{attrs}, {a0 => {index => 0, ro => 1}};
}


done_testing;
