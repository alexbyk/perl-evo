package MyAttrBar;
use Evo '-Attr attr_handler; -Export *';

attr_handler sub ($pkg, $code, @attrs) {
  local $, = '; ';
  no strict 'refs';    ## no critic
  ${"${pkg}::GOT_BAR"} = [$pkg, $code, @attrs];
  return grep { $_ ne 'Bar' } @attrs;
};


1;
