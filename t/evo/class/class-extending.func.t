package main;
use Evo 'Test::More; Evo::Internal::Exception; Symbol delete_package; Module::Loaded';


{
  no warnings 'once';
  *My::Role::external_marked  = sub {'external_marked'};
  *My::Role::external_private = sub {'external_private'};

  package My::Role;
  use Evo -Class, -Loaded, -Export;

  # exported functions are skipped
  sub func : Export {'FUNC'}

  # constants are skipped
  use Fcntl 'SEEK_CUR';
  use constant CONST => 3;

  has 'a1' => 'ok1';
  has 'a2' => 'bad';

  my sub priv1 {'HIDDEN'}
  sub priv2    {'HIDDEN'}
  META->mark_as_private('priv2');
  META->reg_method('external_marked');

  sub pmeth  {'ok'}
  sub ometh1 {'bad'}
  sub ometh2 {'bad'}

  package My::Class;
  use Evo -Class, -Loaded;
  has_over 'a2' => 'ok2';
  has_over 'a3' => 'ok3';    # parent doesn't has it, same as has
  has 'a4'      => 'ok4';    # parent doesn't has it, same as has
  META->mark_as_overridden('ometh2');
  with 'My::Role';
  sub ometh2        {'ok2'}
  sub ometh1 : Over {'ok1'}

  package My::ClassCheckImpl;
  use Evo -Class, -Loaded;

  package My::ClassExtend;
  use Evo -Class;
  extends 'My::Class';
}

GENERAL: {
  my $meta;
  $meta = $My::Class::EVO_CLASS_META;
  isa_ok $meta, 'Evo::Class::Meta';
  ok $meta->is_attr('a1');
  is_deeply [sort $meta->requirements()],
    [sort qw(a1 a2 a3 a4 pmeth ometh1 ometh2 external_marked)];
  is(My::Class->pmeth,           'ok');
  is(My::Class->ometh1,          'ok1');
  is(My::Class->ometh2,          'ok2');
  is(My::Class->external_marked, 'external_marked');

  ok(My::Role->can('priv2'));
  ok(!My::Class->can('priv2'));


  my $obj = My::Class->new;
  is $obj->a1, 'ok1';
  is $obj->a2, 'ok2';
  is $obj->a3, 'ok3';
  is $obj->a4, 'ok4';

  like exception { My::Class->can('has')->('a1') }, qr/already.+a1.+$0/i;
}

SKIP_EXTERNAL: {
  ok(My::Role->can('external_private'));
  ok(!My::Class->can('external_private'));
}

SKIP_EXPORTED_SUBS: {
  ok(My::Role->can('export'));
  ok(My::Role->can('func'));
  ok(!My::Class->can('func'));
}

SKIP_CONSTANTS: {
  ok(My::Role::->can('SEEK_CUR'));
  ok(!My::Class->can('SEEK_CUR'));
  ok(My::Role->can('CONST'));
  ok(!My::Class->can('CONST'));
}

{

  package My::Interface;
  use Evo -Class, -Loaded;
  requires 'r1';
}

# implementation
like exception { My::ClassCheckImpl->can('implements')->('My::Interface') },
  qr/Bad implement.+$0/i;
like exception { My::ClassCheckImpl->can('with')->('My::Interface') }, qr/Bad implement.+$0/i;
no warnings 'once';
Evo::Internal::Util::monkey_patch 'My::ClassCheckImpl', r1 => sub {'ok'};
My::ClassCheckImpl->can('implements')->('My::Interface');

# extends 3 module
is(My::ClassExtend->pmeth,           'ok');
is(My::ClassExtend->external_marked, 'external_marked');


done_testing;
