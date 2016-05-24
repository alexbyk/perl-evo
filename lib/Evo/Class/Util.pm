package Evo::Class::Util;
use Evo '-Export *; Carp croak';

sub croak_bad_value ($value, $name, $msg = undef) : Export {
  my $err = qq'Bad value "$value" for attribute "$name"';
  $err .= ": $msg" if $msg;
  croak $err;
}

# ro just adds chet wrapper
sub compile_attr ($gen, $name, %opts) : Export {
  my $lt = exists $opts{lazy} && (ref $opts{lazy} ? 'CODE' : 'VALUE');
  my $ch = $opts{check};

  my $res;
  if (!$lt) {
    $res = $ch ? $gen->{gsch}->($name, $ch) : $gen->{gs}->($name);
  }
  elsif ($lt eq 'VALUE') {
    $res
      = $ch
      ? $gen->{gsch_value}->($name, $ch, $opts{lazy})
      : $gen->{gs_value}->($name, $opts{lazy});
  }
  elsif ($lt eq 'CODE') {
    $res
      = $ch ? $gen->{gsch_code}->($name, $ch, $opts{lazy}) : $gen->{gs_code}->($name, $opts{lazy});
  }
  else { croak "Bad type $lt"; }

  $res;
}

my @KNOWN = qw(default required lazy check is);

sub parse_style (@attr) : Export {
  my %unknown = my %opts = (@attr % 2 ? (default => @attr) : @attr);
  delete $unknown{$_} for @KNOWN;
  croak "unknown options: " . join(',', sort keys %unknown) if keys %unknown;
  croak "providing default and setting required doesn't make sense"
    if exists $opts{default} && $opts{required};

  _scalar_or_code(\%opts, 'lazy');
  _scalar_or_code(\%opts, 'default');

  %opts;
}

sub _scalar_or_code ($opts, $what) {
  croak qq#"$what" should be either a code reference or a scalar value#
    if ref $opts->{$what} && ref $opts->{$what} ne 'CODE';
}

1;
