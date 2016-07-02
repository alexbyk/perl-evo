package main;
use Evo 'Test::More; Evo::Internal::Exception; Symbol delete_package; Module::Loaded';

mark_as_loaded($_) for qw(My::Interface My::Role My::Class My::ClassCheckImpl My::ClassExtend);

no warnings 'once';

sub test_basic($class) {

  diag "testing $class";
  delete_package($_) for qw(My::Interface My::Role My::Class My::ClassCheckImpl My::ClassExtend);

  my $file = __FILE__;
  ## no critic
  eval qq{
#line 16 $file
      package My::External;
      *My::Role::external = sub {'external'};

      package My::Interface;
      use Evo '$class';
      requires 'r1';

      package My::Role;
      use Evo '$class;';
      use Fcntl 'SEEK_CUR';
      has 'a1'  => 'ok';
      has 'ao1' => 'bad';
      has 'ao2' => 'bad';

      my sub priv1 {'HIDDEN'}
      sub priv2    {'HIDDEN'}
      our \$EVO_CLASS_META;
      \$EVO_CLASS_META->mark_as_private('priv2');
      \$EVO_CLASS_META->reg_method('external');

      sub pmeth  {44}
      sub ometh1 {'bad'}
      sub ometh2 {'bad'}

      package My::Class;
      use Evo '$class;';
      has_over ao1 => 'o1';
      our \$EVO_CLASS_META;
      \$EVO_CLASS_META->mark_as_overridden('ometh2');
      with 'My::Role';
      has_over ao2 => 'o2';
      sub ometh2        {'over'}
      sub ometh1 : Over {'over'}

      package My::ClassCheckImpl;
      use Evo '$class';

      package My::ClassExtend;
      use Evo '$class';
      extends 'My::Role';
  };
  die $@ if $@;

GENERAL: {
    my $meta;
    $meta = eval '$My::Class::EVO_CLASS_META';
    isa_ok $meta, 'Evo::Class::Meta';
    ok $meta->is_attr('a1');
    is_deeply [sort $meta->requirements()], [sort qw(a1 ao1 ao2 pmeth ometh1 ometh2 external)];
    is(My::Class->pmeth,    44);
    is(My::Class->ometh1,   'over');
    is(My::Class->external, 'external');

    ok(!My::Class->can('priv1'));
    ok(!My::Class->can('priv2'));
    ok(!My::Class->can('not_public'));
    ok(!My::Class->can('SEEK_CUR'));

    is $meta->attrs->{ao1}{default}, 'o1';
    is $meta->attrs->{ao2}{default}, 'o2';

    like exception { My::Class->can('has')->('a1') }, qr/already.+a1.+$0/i;
  }

  # implementation
  like exception { My::ClassCheckImpl->can('implements')->('My::Interface') },
    qr/Bad implement.+$0/i;
  like exception { My::ClassCheckImpl->can('with')->('My::Interface') }, qr/Bad implement.+$0/i;
  no warnings 'once';
  Evo::Internal::Util::monkey_patch 'My::ClassCheckImpl', r1 => sub {'ok'};
  My::ClassCheckImpl->can('implements')->('My::Interface');

  # extends
  is(My::ClassExtend->pmeth, 44);

}

test_basic($_) for qw(Evo::Class::Role Evo::Class::Out Evo::Class);

done_testing;
