package Evo::Lib::PP;
use Evo '-Export *; Carp croak';

sub eval_want : Export {
  my ($want, $fn) = (shift, pop);
  if (!defined $want) {
    eval { $fn->(@_); 1 } or return;
    return sub { };
  }
  elsif (!$want) {
    my $res;
    eval { $res = $fn->(@_); 1 } or return;
    return sub {$res};
  }
  else {
    my @res;
    eval { @res = $fn->(@_); 1 } or return;
    return sub {@res};
  }
}

sub try : prototype(&$;$) : Export {
  my ($try, $catch, $fin) = @_;
  my $call = eval_want wantarray, $try;
  $call = eval_want wantarray, my $e = $@, $catch if !$call && $catch;
  if ($call) {  # in normal way we are here, so separate this branch to avoid copying $@ before fin
    $fin->() if $fin;
    return $call->();
  }
  $e = $@;
  $fin->() if $fin;
  die $e;
}

sub uniq : Export {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub strict_opts ($hash, $keys, $level = 1) : Export {
  my %opts = %$hash;
  my @opts = map { delete $opts{$_} } @$keys;
  if (my @remaining = keys %opts) {
    local $Carp::CarpLevel = $level;
    croak "Unknown options: ", join ',', @remaining;
  }
  @opts;
}


1;
