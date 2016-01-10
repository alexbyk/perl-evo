package Evo::Loop;
use Evo '-Realm *; -Export *';
use Evo ':Comp';

use constant DEFAULT => Evo::Loop::Comp::new();

sub start : Export(loop_start) { DEFAULT->start(@_) }

sub timer : Export(loop_timer) { DEFAULT->timer(@_); }

sub timer_remove : Export(loop_timer_remove) {
  DEFAULT->timer_remove(@_);
}


sub handle : Export(loop_handle)             { DEFAULT->handle(@_) }
sub handle_catch : Export(loop_handle_catch) { DEFAULT->handle_catch(@_) }

sub handle_remove : Export(loop_handle_remove) {
  DEFAULT->handle_remove(@_);
}


sub postpone : prototype(&) : Export(loop_postpone) { DEFAULT->postpone(@_) }

sub zone : Export(loop_zone) { DEFAULT->zone(@_) }

1;
