package Evo::Loop;
use Evo '-Export *';
use Evo '::Class';

our $SINGLE = Evo::Loop::Class::new();

sub loop_start : Export { $SINGLE->start(@_) }
sub loop_stop : Export  { $SINGLE->stop(@_) }

sub loop_timer : Export        { $SINGLE->timer(@_); }
sub loop_timer_remove : Export { $SINGLE->timer_remove(@_); }

sub loop_io_in : Export         { $SINGLE->io_in(@_) }
sub loop_io_out : Export        { $SINGLE->io_out(@_) }
sub loop_io_error : Export      { $SINGLE->io_error(@_) }
sub loop_io_remove_in : Export  { $SINGLE->io_remove_in(@_); }
sub loop_io_remove_out : Export { $SINGLE->io_remove_out(@_); }
sub loop_io_remove_all : Export { $SINGLE->io_remove_all(@_); }
sub loop_io_remove_fd : Export  { $SINGLE->io_remove_fd(@_); }

sub loop_zone : Export                    { $SINGLE->zone(@_) }
sub loop_zone_middleware : Export         { $SINGLE->zone_middleware(@_) }
sub loop_postpone : prototype(&) : Export { $SINGLE->postpone(@_) }

1;
