package Evo::Attr;
use Evo::Attr::Class;
use Evo '-Export::Core *';    # because Evo::Export relies on me

*DEFAULT = *Evo::Attr::Class::DEFAULT;

my $MODIFY_CODE_ATTRIBUTES = sub { DEFAULT()->run_code_handlers(@_); };

export_gen attr_handler => sub($provider) {
  sub($handler) {
    my $EXP  = Evo::Export::Exporter::DEFAULT;
    my $ATTR = Evo::Attr::Class::DEFAULT;

    # register handler
    $ATTR->register_code_handler($provider, $handler);

    # add MODIFY_CODE_ATTRIBUTES for provider's export list
    $EXP->add_gen(
      $provider,
      'MODIFY_CODE_ATTRIBUTES',
      sub($dpkg) {
        $ATTR->install_code_handler_in($dpkg, $provider);
        $MODIFY_CODE_ATTRIBUTES;
      }
    );

  };
};


1;
