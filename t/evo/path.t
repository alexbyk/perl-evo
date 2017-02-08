use Evo 'Test::More; Evo::Path';


APPEND: {
  my $path = Evo::Path->new(base => '/hello');
  $path = $path->append('///');
  ok !$path->children->@*;
  $path = $path->append('///1///2///');
  is_deeply $path->children, [1, 2];
}


APPEND: {
  my $path = Evo::Path->new(children => [1, 2]);
  is $path->to_string, "/1/2";
  is "$path", '/1/2';

  $path = Evo::Path->new(base => '/foo', children => [1, 2]);
  is $path->to_string, "/foo/1/2";

  $path = Evo::Path->new(base => 'foo://', children => [1, 2]);
  is $path->to_string, "foo://1/2";

  $path = Evo::Path->new(base => 'foo://bar', children => [1, 2]);
  is $path->to_string, "foo://bar/1/2";

  $path = Evo::Path->new(base => 'foo://bar/', children => [1, 2]);
  is $path->to_string, "foo://bar/1/2";
}


done_testing;
