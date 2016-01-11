package Evo::Loop;
use Evo '-Realm *; -Export *; -Realm *';
use Evo ':Comp';

use constant DEFAULT => Evo::Loop::Comp::new();

sub start : Export(loop_start) { DEFAULT->realm_lord->start(@_) }

sub timer : Export(loop_timer) { DEFAULT->realm_lord->timer(@_); }

sub timer_remove : Export(loop_timer_remove) {
  DEFAULT->realm_lord->timer_remove(@_);
}


sub handle : Export(loop_handle)             { DEFAULT->realm_lord->handle(@_) }
sub handle_catch : Export(loop_handle_catch) { DEFAULT->realm_lord->handle_catch(@_) }

sub handle_remove : Export(loop_handle_remove) {
  DEFAULT->realm_lord->handle_remove(@_);
}


sub postpone : prototype(&) : Export(loop_postpone) { DEFAULT->realm_lord->postpone(@_) }

sub zone : Export(loop_zone) { DEFAULT->realm_lord->zone(@_) }

1;
