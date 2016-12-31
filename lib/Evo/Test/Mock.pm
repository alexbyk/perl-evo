package Evo::Test::Mock;
use Evo '-Class * new:_new; -Export; Carp croak; -Lib eval_want; /::Call';
use Hash::Util::FieldHash 'fieldhash';

fieldhash my %REG;

has 'original_sub';
has 'original_name';
has 'calls';
has 'sub';

our $ORIGINAL;

sub get_original() : prototype() : Export {
  $ORIGINAL or die "Not in mocked subroutine";
}

sub call_original : Export { get_original->(@_); }

sub create_mock ($me, $name, $msub) {
  no strict 'refs';    ## no critic
  my $orig = *{$name}{CODE} or die "No sub $name";
  croak "$name was already mocked" if $REG{$orig};

  my $mock_sub = ref $msub eq 'CODE' ? $msub : $msub ? sub { call_original() } : sub { };

  my $calls = [];
  my $sub   = sub {
    local $ORIGINAL = $orig;
    my $rfn = eval_want wantarray, @_, $mock_sub;
    my $call = Evo::Test::Call->new(args => \@_, exception => $@, result_fn => $rfn);
    push $calls->@*, $call;
    return unless $rfn;
    $rfn->();
  };

  my $mock
    = $me->_new(original_sub => $orig, original_name => $name, sub => $sub, calls => $calls);

  no warnings 'redefine';
  $REG{$sub}++;
  *{$name} = $sub;
  $mock;
}

sub get_call ($self, $n) {
  return unless exists $self->calls->[$n];
  $self->calls->[$n];
}

sub DESTROY($self) {
  ## no critic;
  no strict 'refs';
  no warnings 'redefine';
  *{${\$self->original_name}} = $self->original_sub;
}


1;
