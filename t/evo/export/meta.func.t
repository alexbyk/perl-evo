package main;
use Evo 'Test::More';
use Evo '-Internal::Util';

{

  package My::Foo;
  use Evo 'Evo::Export::Meta; Evo::Export';

  sub import ($me, @list) {
    Evo::Export->install_in(scalar caller, $me, @list);
  }

  my $meta = Evo::Export::Meta->find_or_bind_to(__PACKAGE__);
  $meta->export('foo');
  $meta->export_gen(
    foo_gen => sub ($me, $dest) {
      sub {"gen-$me-$dest"};
    }
  );
  $meta->export_code(foo_anon => sub {'anon'});
  sub foo {'sub'}
}

My::Foo->import('*') for 1 .. 2;

is foo(),      'sub';
is foo_anon(), 'anon';
is foo_gen(),  'gen-My::Foo-main';
ok !Evo::Internal::Util::pkg_stash('main', 'Evo::Export::Meta');
ok Evo::Internal::Util::pkg_stash('My::Foo', 'Evo::Export::Meta');

done_testing;
