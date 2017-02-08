package Evo::Path;
use Evo -Class;
use overload '""' => sub { shift->to_string },
fallback => 1;

has base => '/';
has children => sub { [] };


sub append ($self, $path) {
  $path =~ s#/+$##;
  $path =~ s#^/+##;
  (ref $self)
    ->new(base => $self->base, children => [grep { !!$_ } $self->children->@*, split '/', $path]);
}

sub to_string($self) {
  my $base = $self->base;
  $base .= '/' unless $base =~ m#/$#;
  $base . join '/', $self->children->@*;
}

1;
