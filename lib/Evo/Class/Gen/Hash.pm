package Evo::Class::Gen::Hash;
use Evo '-Export *', '-Class::Util croak_bad_value';
use Carp 'croak';

our @CARP_NOT = ('Evo::Class::Hash', 'Evo::Class::Util');

no strict 'refs';    ## no critic
my $GEN = {map { ($_, *{"gen_$_"}{CODE}) } qw(gs gsch gs_value gsch_value gs_code gsch_code new)};

sub GEN : Export {$GEN}

sub gen_new ($_class, $opts) {

  sub {
    my $class = @_ % 2 ? shift : $_class;
    my %attrs = @_;
    exists $attrs{$_} or croak qq#Attribute "$_" is required# for $opts->{required}->@*;

    foreach my $k (keys %attrs) {
      exists $opts->{known}{$k} or croak qq#Unknown attribute "$k"#;
      if (exists $opts->{check}{$k}) {
        my ($ok, $err) = $opts->{check}{$k}->($attrs{$k});
        croak_bad_value($attrs{$k}, $k, $err) unless $ok;
      }
    }
    exists $attrs{$_} or $attrs{$_} = $opts->{dv}{$_}      for keys $opts->{dv}->%*;
    exists $attrs{$_} or $attrs{$_} = $opts->{dfn}{$_}->(@_) for keys $opts->{dfn}->%*;

    bless \%attrs, $class;
  };
}


sub gen_gs($name) {
  sub {
    return $_[0]->{$name} if @_ == 1;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}

sub gen_gs_value ($name, $value) {
  sub {
    return exists $_[0]->{$name} ? $_[0]->{$name} : $value if @_ == 1;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}

sub gen_gs_code ($name, $fn) {
  sub {
    return exists $_[0]->{$name} ? $_[0]->{$name} : $fn->($_[0]) if @_ == 1;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}


sub gen_gsch ($name, $ch) {
  sub {
    return $_[0]->{$name} if @_ == 1;
    my ($ok, $msg) = $ch->($_[1]);
    croak_bad_value($_[1], $name, $msg) unless $ok;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}

sub gen_gsch_value ($name, $ch, $value) {
  sub {
    return exists $_[0]->{$name} ? $_[0]->{$name} : $value if @_ == 1;
    my ($ok, $msg) = $ch->($_[1]);
    croak_bad_value($_[1], $name, $msg) unless $ok;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}

sub gen_gsch_code ($name, $ch, $code) {
  sub {
    return exists $_[0]->{$name} ? $_[0]->{$name} : $code->($_[0]) if @_ == 1;
    my ($ok, $msg) = $ch->($_[1]);
    croak_bad_value($_[1], $name, $msg) unless $ok;
    $_[0]->{$name} = $_[1];
    $_[0];
  };
}

1;
