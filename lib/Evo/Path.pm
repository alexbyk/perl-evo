package Evo::Path;
use Evo -Class, 'Carp croak';
use overload
  '""'     => sub { shift->to_string },
  fallback => 1;

has base => '/';
has children => sub { [] };

my sub _split ($safe, $path) {
  return if !$path;
  return grep { !!$_ } split '/', $path if !$safe;
  grep {
    $_ ne '..'
      ? 1
      : croak qq#unsafe "$path", use "append_unsafe" instead (or \$fs->cd('..'))#
  } grep { !!$_ && $_ ne '.' } split '/', $path;
}

sub append ($self, $path) {
  (ref $self)->new(base => $self->base, children => [$self->children->@*, _split(1, $path)]);
}

sub append_unsafe ($self, $path) {
  (ref $self)->new(base => $self->base, children => [$self->children->@*, _split(0, $path)]);
}

sub to_string($self) {
  my $base = $self->base;
  $base .= '/' unless $base =~ m#/$#;
  $base . join '/', $self->children->@*;
}

sub from_string ($me, $path = undef, $base = '/') {
  $me->new(base => $base, children => [_split(1, $path)]);
}

1;

=head1 SYNOPSIS

  say Evo::Path->from_string('a/b',    '/base');     # /base/a/b
  say Evo::Path->from_string('/a/b//', '/base/');    # /base/a/b

  my $path = Evo::Path->from_string('part', '/base');
  say $path->append('foo/bar');                      # /base/foo/bar
  say $path->append('/foo/bar/');                    # /base/foo/bar
  say $path->append_unsafe('/foo/../bar');           # /base/foo/../bar

=head1 METHODS

=head2 append

Append child path to the current and return a new C<Evo::Path> instance with the same C<base>.
This functions should protect you from file traverse vulnerabilities

=head2 append_unsafe

Like append, but don't protect from C<..> parts in path

=cut
