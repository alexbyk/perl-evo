package Evo::Export;
use Evo '-Attr *; ::Core *';

export_proxy 'Evo::Export::Core', '*';

sub _attr_handler ($pkg, $code, @attrs) {
  my (@bad, @good);
  foreach my $attr (@attrs) {
    my ($attr_name, $val) = _parse_attr($attr);
    $attr_name eq 'Export' ? push @good, $val : push @bad, $attr;
  }

  foreach my $name (@good) {
    my @names = $name ? ($name) : Evo::Lib::Bare::find_subnames($pkg, $code);
    Evo::Export::Class::DEFAULT->add_gen($pkg, $_, sub {$code}) for @names;
  }


  return @bad;
}


# pay attention: without provided name all aliases will be found by _find_subnames and exported
attr_handler \&_attr_handler;

sub _parse_attr($attr) {
  $attr =~ /(\w+) ( \( \s* (\w+) \s* \) )?/x;
  return ($1, $3);
}


1;

=head1 DESCRIPTION

Standart L<Exporter> wasn't good enough for me, so I've written a new one from the scratch

=head1 SYNOPSYS

  # need separate file My/Lib.pm
  package My::Lib;
  use Evo '-Export *';
  
  # export foo
  sub foo : Export { say 'foo' }

  # export other as bar
  sub other : Export(bar) { say 'bar' }

  # test.pl
  package main;
  use Evo 'My::Lib *';
  foo();
  bar();

=head1 IMPORTING

  use Evo;
  use Evo 'Evo::Eval eval_try';
  use Evo '-Promise promise deferred';

For convenient, you can load all above in one line

  use Evo '-Eval eval_try; -Promise promise deferred';

C<*> means load all. C<-> is a shortcut. See L<Evo/"shortcuts>

=head2 what to import and how

You can rename subroutines to avoid method clashing

  # import promise as prm
  use Evo '-Promise promise:prm';

You can use C<*> with exclude C<-> for convinient
  
  # import all except "deferred"
  use Evo '-Promise *, -deferred';

If one name clashes with yours, you can import all except that name and import
renamed version of that name

  # import all as is but only deferred will be renamed to "renamed_deferred"
  use Evo '-Promise *, -deferred, deferred:renamed_deferred';



=head1 EXPORTING

Using attribute C<Export>

  package main;
  use Evo;

  {

    package My::Lib;
    use Evo -Loaded; # don't needed in the real code
    use Evo '-Export *';

    sub foo : Export {say 'foo'}

  }

  use Evo 'My::Lib foo';
  foo();

Pay attention that module should export '*', to install all unneccessary stuff, including C<MODIFY_CODE_ATTRIBUTES> and C<import>. But if you want, you can import them by hand, and this isn't recommended

You can export with another name  

  # export as bar
  sub foo : Export(bar) {say 'foo'}

=head4 export 'foo';

C<Export> signature is more preffered way, but if you wish

  # export foo
  export 'foo';

  # export "foo" under name "bar"
  export 'foo:bar';

Trying to export not existing subroitine will cause an exception

=head4 export_anon

Export function, that won't be available in the source class

  # My::Lib now exports foo, but My::Lib::foo doesn't exist
  export_anon foo => sub { say "hello" };

=head4 export_proxy

  # reexport all from My::Other
  export_proxy 'My::Other', '*';


  # reexport "foo" from My::Other
  export_proxy 'My::Other', 'foo';

  # reexport "foo" from My::Other as "bar"
  export_proxy 'My::Other', 'foo:bar';

=head4 export_gen

  
  package main;
  use Evo;

  {

    # BEGIN and Loaded only for copy-paste example
    package My::Lib;
    use Evo '-Export *; -Loaded';

    export_gen foo => sub ($class) {
      say "$class requested me";
      sub {"hello, $class"};
    };
  };


  My::Lib->import('*');
  foo();

Very powefull and most exciting feature. C<Evo::Export> exports generators, that produces subroutines. Consider it as a 3nd dimension in 3d programming

Implementation garanties that one module will get the same (cashed) generated unit (if it'l import twice or import from module that reimport the same thing), but different module will get another one

  use Evo 'Evo::Class has'; 
  use Evo 'Evo::Class has'; 

C<has> was imported twice, but generated only once. If some class will do something C<export_proxy 'Evo::Class', 'has'>, you can export that C<has> and it will be the same subroutine

For example, you can use it to check, if requester class has some methods and than use it directly, if C<$self-E<gt>method()> isn't good choise

    export_gen foo => sub ($class) {
      my $method = $class->can("name") or die "provide name";
      sub { say $method->() };
    };

=head4 import

By default, this method will be exported and do the stuff. If you need replace C<import> of your module, exclude it by C<use Evo '-Export *, -import'>

=head4 import_all

  use Evo '-Export *, -import, import_all:import';

Just like C</import> but treats empty list as '*'.

=cut
