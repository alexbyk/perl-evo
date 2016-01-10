package Evo::Want;
use Evo '-Export *';
use Carp 'croak';
export qw(WANT_LIST WANT_SCALAR WANT_VOID want_is_list want_is_scalar want_is_void);

use constant WANT_LIST   => 1;
use constant WANT_SCALAR => '';
use constant WANT_VOID   => undef;

my $ERROR = "useless use";
sub want_is_list { croak $ERROR unless defined wantarray; defined $_[0] && $_[0] && $_[0] == 1; }
sub want_is_scalar { croak $ERROR unless defined wantarray; defined $_[0] && !$_[0] }
sub want_is_void { croak $ERROR unless defined wantarray; !defined $_[0] }

1;

=head1 DESCRIPTION

Provides some usefull constants and utils for testing C<wantarray>: C<WANT_LIST>, C<WANT_SCALAR>, C<WANT_VOID>, C<want_is_list>, C<want_is_scalar>, C<want_is_void>

=cut
