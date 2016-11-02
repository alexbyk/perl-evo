package Evo::Class::Meta;
use Evo 'Carp croak; Scalar::Util reftype; -Lib strict_opts; -Internal::Util; Module::Load ()';
use Evo '/::Attrs *';


our @CARP_NOT = qw(Evo::Class);

sub register ($me, $package) {
  my $self = Evo::Internal::Util::pkg_stash($package, $me);
  return $self if $self;
  $self = bless {
    package    => $package,
    private    => {},
    attrs      => Evo::Class::Attrs->new,
    methods    => {},
    reqs       => {},
    overridden => {}
  }, $me;
  Evo::Internal::Util::pkg_stash($package, $me, $self);
  $self;
}

sub find_or_croak ($self, $package) {
  Evo::Internal::Util::pkg_stash($package, $self) or croak "$package isn't Evo::Class";
}

sub package($self) { $self->{package} }
sub attrs($self)   { $self->{attrs} }
sub methods($self) { $self->{methods} }
sub reqs($self)    { $self->{reqs} }

sub overridden($self) { $self->{overridden} }
sub private($self)    { $self->{private} }

sub mark_as_overridden ($self, $name) {
  $self->overridden->{$name} = 1;
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
  $self->attrs->exists($name);
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

sub reg_attr ($self, $name, @opts) {
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  croak qq{$pkg already has subroutine "$name"} if Evo::Internal::Util::names2code($pkg, $name);
  my $sub = $self->attrs->gen_attr($name, @opts);    # register
  Evo::Internal::Util::monkey_patch $pkg, $name, $sub;
}

sub reg_attr_over ($self, $name, @opts) {
  _check_valid_name($self, $name);
  $self->mark_as_overridden($name);
  my $sub = $self->attrs->gen_attr($name, @opts);    # register
  my $pkg = $self->package;
  Evo::Internal::Util::monkey_patch_silent $pkg, $name, $sub;
}

# means register external sub as method. Because every sub in the current package
# is public by default
sub reg_method ($self, $name) {
  _check_exists_valid_name($self, $name);
  my $pkg = $self->package;
  my $code = Evo::Internal::Util::names2code($pkg, $name) or croak "$pkg::$name doesn't exist";
  $self->methods->{$name}++;
}

sub _public_attrs_slots($self) {
  grep { !$self->is_private($_->{name}) } $self->attrs->slots;
}

sub _public_methods_map($self) {
  my $pkg = $self->package;
  map { ($_, Evo::Internal::Util::names2code($pkg, $_)) }
    grep { !$self->is_private($_) && $self->is_method($_) }
    Evo::Internal::Util::list_symbols($pkg);
}

sub public_attrs($self) {
  map { $_->{name} } $self->_public_attrs_slots;
}

sub public_methods($self) {
  my %map = $self->_public_methods_map;
  keys %map;
}


sub extend_with ($self, $source_p) {
  $source_p = Evo::Internal::Util::resolve_package($self->package, $source_p);
  Module::Load::load($source_p);
  my $source  = $self->find_or_croak($source_p);
  my $dest_p  = $self->package;
  my %reqs    = $source->reqs()->%*;
  my %methods = $source->_public_methods_map();

  my @new_attrs;

  foreach my $name (keys %reqs) { $self->reg_requirement($name); }

  foreach my $slot ($source->_public_attrs_slots) {
    next if $self->is_overridden($slot->{name});
    $self->reg_attr(@$slot{qw(name type value check ro inject)});
    push @new_attrs, $slot->{name};
  }

  foreach my $name (keys %methods) {
    next if $self->is_overridden($name);
    croak qq/$dest_p already has a subroutine with name "$name"/
      if Evo::Internal::Util::names2code($dest_p, $name);
    croak
      qq/$dest_p already has a (probably inherited by \@ISA) method "$name", define implementation with :Over tag/
      if $dest_p->can($name);
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
  (keys($self->reqs->%*), $self->public_attrs, $self->public_methods);
}

sub check_implementation ($self, $inter_class) {
  $inter_class = Evo::Internal::Util::resolve_package($self->package, $inter_class);
  Module::Load::load($inter_class);
  my $class = $self->package;
  my $inter = $self->find_or_croak($inter_class);
  my @reqs  = sort $inter->requirements;
  croak qq{Empty class "$inter_class", nothing to check} unless @reqs;

  my @not_exists = grep { !($self->is_attr($_) || $class->can($_)); } @reqs;
  return $self if !@not_exists;

  croak qq/Bad implementation of "$inter_class", missing in "$class": /, join ';', @not_exists;
}

# -- class methods for usage from other modules too


# rtype: default, default_code, required, lazy, relaxed
# rvalue is used as meta for required(di), default and lazy
# check?
# is_ro?

my @KNOWN_HAS = qw(default required lazy check is inject);

sub parse_attr ($me, @attr) {
  my %unknown = my %opts = (@attr % 2 ? (default => @attr) : @attr);
  delete $unknown{$_} for @KNOWN_HAS;
  croak "unknown options: " . join(',', sort keys %unknown) if keys %unknown;

  #use constant {I_NAME => 0, I_TYPE => 1, I_RO => 2, I_CHECK => 3, I_VALUE => 4};
  my ($type, $ro, $check, $value);

  # detect rtype
  my $seen = 0;
  if (exists $opts{default}) {
    croak qq#"default" should be either a code reference or a scalar value#
      if ref($opts{default}) && (reftype($opts{default}) // '') ne 'CODE';
    ++$seen;
    $type = ref($opts{default}) ? ECA_DEFAULT_CODE : ECA_DEFAULT;
    $value = $opts{default};
  }
  do { ++$seen; $type = ECA_REQUIRED; } if $opts{required};
  if (exists $opts{lazy}) {
    croak qq#"lazy" should be a code reference# if (reftype($opts{lazy}) // '') ne 'CODE';
    ++$seen;
    $type  = ECA_LAZY;
    $value = $opts{lazy};
  }
  croak qq{providing more than one of "default", "lazy", "required" doesn't make sense}
    if $seen > 1;

  croak qq#"check" should be a code reference#
    if exists($opts{check}) && (reftype($opts{check}) // '') ne 'CODE';

  my $is = $opts{is} // 'rw';
  croak qq#invalid "is": "$is"# unless $is eq 'ro' || $is eq 'rw';

  $ro = $is eq 'ro' ? 1 : 0;
  $check = $opts{check} if exists $opts{check};
  $type ||= ECA_SIMPLE;

  return ($type, $value, $check, $ro, $opts{inject});
}

sub info($self) {
  my %info = (
    public => {
      methods => [sort $self->public_methods],
      attrs   => [sort $self->public_attrs],
      reqs    => [sort keys($self->reqs->%*)],
    },
    overridden => [sort keys($self->overridden->%*)],
    private    => [sort keys($self->private->%*)],
  );
  \%info;
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


=head2 mark_as_private

If you want to hide method, you should use C<my sub> feature. But sometimes this also will help. It doesn't hide you method from being executed, it hides it from inheritance

  package Foo;
  use Evo -Class;
  sub foo { }

  local $, = ' ';
  say 'LIST: ', META->public_methods;

  META->mark_as_private('foo');    # hide foo
  say 'LIST: ', META->public_methods;

But C<foo> is still available via C<Foo::-E<gt>foo>

=head1 DUMPING (EXPERIMENTAL)

  package My::Foo;
  use Evo -Class;
  has 'foo';

  use Data::Dumper;
  say Dumper __PACKAGE__->META->info;

=cut
