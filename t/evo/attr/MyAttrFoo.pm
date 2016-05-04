package MyAttrFoo;
use Evo '-Attr attr_handler; -Export *';

attr_handler sub ($pkg, $code, @attrs) {
  local $, = '; ';
  no strict 'refs';    ## no critic
  ${"${pkg}::GOT_FOO"} = [$pkg, $code, @attrs];
  return grep { $_ ne 'Foo' } @attrs;
};

1;
