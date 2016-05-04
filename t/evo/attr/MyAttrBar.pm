package MyAttrBar;
use Evo '-Attr *; -Export::Core *';

export_proxy '-Attr', 'MODIFY_CODE_ATTRIBUTES';

sub import {
  export_install_in(scalar caller, @_);
  attr_install_code_handler_in(scalar caller);
}

attr_register_code_handler sub ($pkg, $code, @attrs) {
  local $, = '; ';
  no strict 'refs'; ## no critic
  ${"${pkg}::GOT_BAR"} = [$pkg, $code, @attrs];
  return grep { $_ ne 'Bar' } @attrs;
};


1;
