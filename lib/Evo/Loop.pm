package Evo::Loop;
use Evo '-Realm *; -Export *; -Realm *';
use Evo ':Comp';

use constant DEFAULT => Evo::Loop::Comp::new();

sub start : Export(loop_start) { realm_lord(DEFAULT)->start(@_) }

sub timer : Export(loop_timer) { realm_lord(DEFAULT)->timer(@_); }

sub timer_remove : Export(loop_timer_remove) {
  realm_lord(DEFAULT)->timer_remove(@_);
}


sub handle : Export(loop_handle)             { realm_lord(DEFAULT)->handle(@_) }
sub handle_catch : Export(loop_handle_catch) { realm_lord(DEFAULT)->handle_catch(@_) }

sub handle_remove : Export(loop_handle_remove) {
  realm_lord(DEFAULT)->handle_remove(@_);
}


sub postpone : prototype(&) : Export(loop_postpone) { realm_lord(DEFAULT)->postpone(@_) }

sub zone : Export(loop_zone) { realm_lord(DEFAULT)->zone(@_) }

1;
