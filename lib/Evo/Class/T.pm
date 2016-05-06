package Evo::Class::T;
use Evo '-Export *; Carp croak; List::Util any';

sub t_enum(@list) : Export {
  croak "empty enum list" unless @list;
  sub($v) {
    any { defined $v ? defined $_ ? $_ eq $v : !defined $v : !defined $_ } @list;
  };
}

1;

=head1 DESCRIPTION

Types for L<Evo::Class/"check">. Right now there aren't so many of them.

=head1 SYNOPSYS

  {

    package My::Foo;
    use Evo -Class, '-Class::T *';
    has status => check => t_enum("ok", "not ok");

  }

  my $obj = My::Foo::new(status => "ok");
  $obj->status("badVal");    # dies

=head1 FUNCTIONS

=head2 t_enum

  my $check = t_enum("ok", "good");
  my($ok, $err) = $check->("bad");

Enum checker - a value must be one of the list;

=cut
