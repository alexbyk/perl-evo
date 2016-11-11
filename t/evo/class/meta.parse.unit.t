package main;
use Evo 'Test::More; -Class::Attrs *; -Class::Syntax *; -Class::Meta; -Internal::Exception';

sub parse { Evo::Class::Meta->parse_attr(@_); }

ERRORS: {
  like exception { parse 'foo', 'rw' }, qr/foo,rw.+$0/;
  like exception { parse optional, 'foo' }, qr/"optional".+"foo".+$0/;
  like exception { parse lazy }, qr/"lazy".+code reference.+$0/;
  like exception { parse lazy, {} }, qr/"lazy".+code reference.+$0/;
  like exception { parse lazy, 'foo' }, qr/"lazy".+code reference.+$0/;
  like exception { parse {} }, qr/default\("HASH(.+)"\).+code reference.+$0/;
}

PARSE: {
  my ($dc, $check) = (sub {1}, sub {2});
  is_deeply [parse()],   [ECA_REQUIRED, (undef) x 2, 1, undef];
  is_deeply [parse(rw)], [ECA_REQUIRED, (undef) x 2, 0, undef];

  is_deeply [parse(optional)], [ECA_OPTIONAL, (undef) x 2, 1, undef];
  is_deeply [parse(optional, rw)], [ECA_OPTIONAL, (undef) x 2, 0, undef];

  is_deeply [parse('foo')], [ECA_DEFAULT, 'foo', undef, 1, undef];
  is_deeply [parse('foo', rw)], [ECA_DEFAULT, 'foo', undef, 0, undef];

  is_deeply [parse($dc)], [ECA_DEFAULT_CODE, $dc, undef, 1, undef];
  is_deeply [parse($dc, rw)], [ECA_DEFAULT_CODE, $dc, undef, 0, undef];

  is_deeply [parse($dc, lazy)], [ECA_LAZY, $dc, undef, 1, undef];
  is_deeply [parse(lazy, $dc, rw)], [ECA_LAZY, $dc, undef, 0, undef];

  is_deeply [parse(optional)], [ECA_OPTIONAL, undef, undef, 1, undef];
  is_deeply [parse(optional, rw)], [ECA_OPTIONAL, undef, undef, 0, undef];

  is_deeply [parse(inject 'Foo::Bar')], [ECA_REQUIRED, undef, undef, 1, 'Foo::Bar'];
  is_deeply [parse(optional, rw, inject 'Foo::Bar')], [ECA_OPTIONAL, undef, undef, 0, 'Foo::Bar'];

  is_deeply [parse(check $check)], [ECA_REQUIRED, undef, $check, 1, undef];
  is_deeply [parse(rw, optional, check $check)], [ECA_OPTIONAL, undef, $check, 0, undef];
}



done_testing;
