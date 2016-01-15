package Evo::Loop;
use Evo '-Realm *; -Export *';
use Evo ':Comp';

use constant DEFAULT => Evo::Loop::Comp::new();

sub loop_start : Export        { DEFAULT->realm_lord->start(@_) }
sub loop_timer : Export        { DEFAULT->realm_lord->timer(@_); }
sub loop_timer_remove : Export { DEFAULT->realm_lord->timer_remove(@_); }

sub loop_io_in : Export         { DEFAULT->realm_lord->io_in(@_) }
sub loop_io_out : Export        { DEFAULT->realm_lord->io_out(@_) }
sub loop_io_error : Export      { DEFAULT->realm_lord->io_error(@_) }
sub loop_io_remove_in : Export  { DEFAULT->realm_lord->io_remove_in(@_); }
sub loop_io_remove_out : Export { DEFAULT->realm_lord->io_remove_out(@_); }
sub loop_io_remove_all : Export { DEFAULT->realm_lord->io_remove_all(@_); }

sub loop_zone : Export                    { DEFAULT->realm_lord->zone(@_) }
sub loop_postpone : prototype(&) : Export { DEFAULT->realm_lord->postpone(@_) }

1;
