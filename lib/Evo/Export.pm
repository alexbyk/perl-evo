package Evo::Export;
use Evo -Export::Exporter;
use Carp 'croak';
use Evo::Util;

my $EXPORTER;
sub EXPORTER() {$EXPORTER}

BEGIN {
  $EXPORTER = Evo::Export::Exporter::new();
}

# + export export_gen export_anon export_proxy export_requires export_hooks
my @EXPORT = qw(
  import export_install_in
  MODIFY_CODE_ATTRIBUTES EXPORTER);
EXPORTER->add_sub(__PACKAGE__, $_) for @EXPORT;

sub import { export_install_in(scalar caller, @_); }

sub export_install_in($dst, $src, @list) { EXPORTER->install($src, $dst, @list) if @list; }

# pay attention: without provided name all aliases will be found by _find_subnames and exported
sub MODIFY_CODE_ATTRIBUTES($pkg, $code, @attrs) {
  my (@bad, @good);
  foreach my $attr (@attrs) {
    my ($attr_name, $val) = _parse_attr($attr);
    $attr_name eq 'Export' ? push @good, $val : push @bad, $attr;
  }
  return @bad if @bad;

  foreach my $name (@good) {
    my @names = $name ? ($name) : Evo::Util::find_subnames($pkg, $code);
    EXPORTER->add_gen($pkg, $_, sub {$code}) for @names;
  }

  return;
}

sub _parse_attr($attr) {
  $attr =~ /(\w+) ( \( \s* (\w+) \s* \) )?/x;
  return ($1, $3);
}


sub _add_gen($name, $gen) { EXPORTER->add_gen(__PACKAGE__, $name, $gen); }

_add_gen export_gen => sub($dst) {
  sub($name, $gen) { EXPORTER->add_gen($dst, $name, $gen) }
};

_add_gen export_anon => sub($dst) {
  sub {
    my ($name, $fn) = @_;
    EXPORTER->add_gen($dst, $name, sub {$fn});
  };
};

_add_gen export => sub($dst) {
  sub { EXPORTER->add_sub($dst, $_) for @_ }
};

_add_gen export_proxy => sub($dst) {
  sub($epkg,@list) { EXPORTER->proxy($dst, $epkg, @list); }
};

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
  use Evo;
  use My::Lib '*';
  foo();
  bar();

=head1 IMPORTING

  use Evo;
  use Evo::Eval 'eval_try';
  use Evo::Promise 'promise', 'deferred';

For convenient, you can load all above in one line

  use Evo '-Eval eval_try; -Promise promise, deferred';

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

  use My::Lib 'foo';
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

  use Evo::Comp 'has'; 
  use Evo::Comp 'has'; 

C<has> was imported twice, but generated only once. If some class will do something C<export_proxy 'Evo::Comp', 'has'>, you can export that C<has> and it will be the same subroutine

For example, you can use it to check, if requester component has some methods and than use it directly, if C<$self-E<gt>method()> isn't good choise

    export_gen foo => sub ($class) {
      my $method = $class->can("name") or die "provide name";
      sub { say $method->() };
    };

=cut
