package Evo::Class::Meta;
use Evo -Internal::Util;
use Evo 'Carp croak; -Internal::Util; Module::Load ()';

our @CARP_NOT = qw(Evo::Class::Role Evo::Class::Out Evo::Class
  Evo::Class::Common::StorageFunctions Evo::Class::Common::RoleFunctions);

no warnings 'redefine';    ## no critic

sub register ($me, $package) {
  my $self = Evo::Internal::Util::pkg_stash($package, $me);
  return $self if $self;
  $self = bless {
    package     => $package,
    _private    => {},
    _attrs      => {},
    _methods    => {},
    _reqs       => {},
    _overridden => {}
  }, $me;
  Evo::Internal::Util::pkg_stash($package, $me, $self);
  $self;
}

sub find_or_croak ($self, $package) {
  Evo::Internal::Util::pkg_stash($package, $self) or croak "$package isn't Evo::Class";
}

sub package($self) { $self->{package} }

sub attrs($self)      { $self->{_attrs} }
sub methods($self)    { $self->{_methods} }
sub reqs($self)       { $self->{_reqs} }
sub overridden($self) { $self->{_overridden} }
sub private($self)    { $self->{_private} }

sub mark_as_overridden ($self, $name) {
  $self->overridden->{$name}++;
  $self;
}

sub is_overridden ($self, $name) {
  $self->overridden->{$name};
}

sub mark_as_private ($self, $name) {
  $self->private->{$name} = 1;
}

sub is_private ($self, $name) {
  $self->private->{$name};
}

# first check methods, if doesn't exists, try to determine if there is a sub in package
# if a sub is compiled in the same package, it's a public, if not(imported or xsub), it's private

sub is_method ($self, $name) {
  return 1 if $self->methods->{$name};
  my $pkg = $self->package;
  my $code = Evo::Internal::Util::names2code($pkg, $name) or return;
  my ($realpkg, $realname, $xsub) = Evo::Internal::Util::code2names($code);
  return !$xsub && $realpkg eq $pkg;
}

sub is_attr ($self, $name) {
  $self->attrs->{$name};
}

# has attribute or sub
sub has_name ($self, $name) {
  $self->attrs->{$name} || Evo::Internal::Util::names2code($self->package, $name);
}

sub _check_valid_name ($self, $name) {
  croak(qq{"$name" is invalid name}) unless Evo::Internal::Util::check_subname($name);
}

sub _check_exists ($self, $name) {
  my $pkg = $self->package;
  croak qq{$pkg already has attribute "$name"} if $self->is_attr($name);
  croak qq{$pkg already has method "$name"}    if $self->is_method($name);
}

sub _check_exists_valid_name ($self, $name) {
  _check_valid_name($self, $name);
  _check_exists($self, $name);
}

sub reg_attr ($self, $name, %opts) {
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  croak qq{$pkg already has subroutine "$name"} if Evo::Internal::Util::names2code($pkg, $name);
  $self->attrs->{$name} = \%opts;
}

sub reg_attr_over ($self, $name, %opts) {
  _check_valid_name($self, $name);
  $self->attrs->{$name} = \%opts;
  $self->mark_as_overridden($name);
}

# means register external sub as method. Because every sub in the current package
# is public by default
sub reg_method ($self, $name) {
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  my $code = Evo::Internal::Util::names2code($pkg, $name) or croak "$pkg::$name doesn't exist";
  $self->methods->{$name}++;
}

sub public_methods($self) {
  my $pkg = $self->package;
  map { ($_, Evo::Internal::Util::names2code($pkg, $_)) }
    grep { !$self->is_private($_) && $self->is_method($_) }
    Evo::Internal::Util::list_symbols($pkg);
}

sub public_attrs($self) {
  map { ($_, $self->attrs->{$_}) } grep { !$self->is_private($_) } keys $self->attrs->%*;
}

sub extend_with ($self, $source_p) {
  Module::Load::load($source_p);
  my $source  = $self->find_or_croak($source_p);
  my $dest_p  = $self->package;
  my %reqs    = $source->reqs()->%*;
  my %attrs   = $source->public_attrs();
  my %methods = $source->public_methods();

  my @new_attrs;

  foreach my $name (keys %reqs) { $self->reg_requirement($name); }

  foreach my $name (keys %attrs) {
    next if $self->is_overridden($name);
    croak qq/$dest_p already has a subroutine with name "$name"/
      if Evo::Internal::Util::names2code($dest_p, $name);
    $self->reg_attr($name, $attrs{$name}->%*);
    push @new_attrs, $name;
  }

  foreach my $name (keys %methods) {
    next if $self->is_overridden($name);
    croak qq/$dest_p already has a subroutine with name "$name"/
      if Evo::Internal::Util::names2code($dest_p, $name);
    _check_exists($self, $name);    # prevent patching before check
    Evo::Internal::Util::monkey_patch $dest_p, $name, $methods{$name};
    $self->reg_method($name);
  }
  @new_attrs;
}


sub reg_requirement ($self, $name) {
  $self->reqs->{$name}++;
}

sub requirements($self) {
  my %all = ($self->public_attrs, $self->public_methods, $self->reqs->%*);
  keys %all;
}

sub check_implementation ($self, $inter_class) {
  Module::Load::load($inter_class);
  my $class = $self->package;
  my $inter = $self->find_or_croak($inter_class);
  my @reqs  = sort $inter->requirements;
  croak qq{Empty class "$inter_class", nothing to check} unless @reqs;

  my @not_exists = grep { !($self->is_attr($_) || $class->can($_)); } @reqs;
  return $self if !@not_exists;

  croak qq/Bad implementation of "$inter_class", missing in "$class": /, join ';', @not_exists;
}

my @KNOWN = qw(default required lazy check is);

sub parse_attr ($self, @attr) {
  my %unknown = my %opts = (@attr % 2 ? (default => @attr) : @attr);
  delete $unknown{$_} for @KNOWN;
  croak "unknown options: " . join(',', sort keys %unknown) if keys %unknown;
  croak "providing default and setting required doesn't make sense"
    if exists $opts{default} && $opts{required};

  croak qq#"default" should be either a code reference or a scalar value#
    if ref $opts{default} && ref $opts{default} ne 'CODE';

  croak qq#"lazy" should be a code reference# if exists $opts{lazy} && ref $opts{lazy} ne 'CODE';
  croak qq#"check" should be a code reference#
    if exists $opts{check} && ref $opts{check} ne 'CODE';

  if ($opts{is}) {
    croak qq#invalid "is": "$opts{is}"# unless $opts{is} eq 'ro' || $opts{is} eq 'rw';
  }
  %opts;
}


1;

=head1 METHODS

=head2 register

Register a meta instance only once. The second invocation will return the same instance.
But if it will be called from another subclass, die. This is a protection from the fool

Meta is stored in C<$Some::Class::META_CLASS> global variable and lives as long as a package.

=head1 IMPLEMENTATION NOTES

=head2 overridden

"overridden" means this symbol will be skept during L</extend_with> so if you marked something as overridden, you should define method or sub yourself too.  This is not a problem with C<sub foo : Over {}> or L</reg_attr_over> because it marks symbol as overridden and also registers a symbol.

BUT!!!
Calling L</reg_attr_over> should be called 


=head2 private

Mark something as private (even if it doesn't exist) to skip at from L</public_*>. But better use C<my sub foo {}> feature

=head2 reg_method

All methods compiled in the class are public by default. But what to do if you make a method by monkey-patching or by extending? Use C</reg_method>

  package Foo;
  use Evo 'Scalar::Util(); -Class::Meta';
  my $meta = Evo::Class::Meta->register(__PACKAGE__);

  no warnings 'once';
  *lln = \&Scalar::Util::looks_like_number;

  # nothing, because lln was compiled in Scalar::Util
  say $meta->public_methods;

  # fix this
  $meta->reg_method('lln');
  say $meta->public_methods;

=head2 check_implementation

If implementation requires "attribute", L</reg_attr> should be called before checking implementation 

=cut
