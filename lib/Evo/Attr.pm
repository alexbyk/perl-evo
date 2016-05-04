package Evo::Attr;
use Evo::Attr::Class;
use Evo '-Export::Core *';


sub import {
  my $caller = caller;
  export_install_in($caller, @_);
}

*DEFAULT = *Evo::Attr::Class::DEFAULT;

export_gen MODIFY_CODE_ATTRIBUTES => sub($dest) {
  sub { DEFAULT()->run_code_handlers(@_); };
};


export_gen attr_register_code_handler => sub($provider) {
  sub($handler) {
    DEFAULT()->register_code_handler($provider, $handler);
  };

};

export_gen attr_install_code_handler_in => sub($provider) {
  sub($dest) {
    DEFAULT()->install_code_handler_in($dest, $provider);
  };
};

export_gen attr_run_code_handlers => sub($provider) {
  sub($dest) {
    DEFAULT()->install_code_handler_in($dest, $provider);
  };
};
1;
