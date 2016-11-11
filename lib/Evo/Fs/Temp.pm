package Evo::Fs::Temp;
use Evo 'File::Temp; File::Spec::Functions file_name_is_absolute';
use Evo '-Class * -new new:_new';
use Carp 'croak';

with '-Fs';

sub new : Over {
  my $fs = _new(shift, @_);
  $fs->make_tree($fs->cwd);
  $fs;
}

has 'root', check sub($v) { file_name_is_absolute($v) }, sub { File::Temp->newdir };

sub path2real ($self, $path) : Over {
  my (undef, $dir,  $last)  = File::Spec->splitpath($self->to_abs($path));
  my ($rvol, $rdir, $rlast) = File::Spec->splitpath($self->root);
  my $realdir = File::Spec->catdir($rdir, $rlast, $dir);
  File::Spec->catpath($rvol, $realdir, $last);
}

sub cd ($self, $path) : Over {
  croak "No such directory $path" unless $self->stat($path)->is_dir;
  $self->cdm($path);
}

sub cdm ($self, $path) : Over {
  my $abs = $self->to_abs($path);
  my $clone = (ref $self)->new(cwd => $abs, root => $self->root);
}


1;

=head1 DESCRIPTION

Like L<Evo::Fs::Disk> but with root as a temporary directory.
Works like C<chroot>. Usefull for testing purposes

=head1 ATTRIBUTES

=head2 root

A root dir, will be appended to every path

=cut
