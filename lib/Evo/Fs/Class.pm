package Evo::Fs::Class;
use Evo '/::Stat; /::File; /::Dir';
use Evo -Class;
use Evo 'Carp croak)';
use Fcntl qw(:seek O_RDWR O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND O_EXCL :flock);
use Evo 'File::Spec; File::Path; Cwd() abs_path; File::Basename fileparse';
use Time::HiRes ();
use List::Util 'first';
use Errno qw(EAGAIN);
use Scalar::Util;

our @CARP_NOT = qw(Evo::Fs::Class::Temp);

{
  # same as to_abs
  no warnings 'once';
  *path2real = *to_abs;
};

#sub new {
#  my $fs = _new(shift, @_);
#  croak "${\$fs->cwd} doesn't exists" unless $fs->stat($fs->cwd)->is_dir;
#  $fs;
#}

my $CWD = Cwd::getcwd();
has
  'cwd' => $CWD,                                                # on module load
  check => sub($v) { File::Spec->file_name_is_absolute($v) },
  is    => 'ro';


sub cd ($self, $path) {
  my $abs = $self->to_abs($path);
  my $clone = (ref $self)->new(cwd => $abs);
}

sub cdm ($self, $path) {
  $self->make_tree($path);
  $self->cd($path);
}


sub file ($self, $path) {
  Evo::Fs::File->new(path => $self->to_abs($path));
}

sub dir ($self, $path) {
  Evo::Fs::Dir->new(path => $self->to_abs($path));
}

sub to_abs ($self, $path) {
  File::Spec->rel2abs($path, $self->cwd);
}


sub exists ($self, $path) {
  -e $self->path2real($path);
}


sub mkdir ($self, $path, $perm = undef) {
  my $real = $self->path2real($path);
  &CORE::mkdir($real, defined $perm ? $perm : ()) or croak "$real: $!";
}

sub make_tree ($self, $path, $perms = undef) {
  my $real = $self->path2real($path);
  my %opts = (error => \my $err);
  $opts{chmod} = $perms if defined $perms;
  File::Path::make_path($real, \%opts);
  croak join('; ', map { $_->%* } @$err) if @$err;    # TODO: test
}

sub symlink ($self, $to_path, $link_path) {
  CORE::symlink($self->path2real($to_path), $self->path2real($link_path))
    or croak "symlink $to_path $link_path: $!";
}

sub link ($self, $to_path, $link_path) {
  CORE::link($self->path2real($to_path), $self->path2real($link_path))
    or croak "hardlink $to_path $link_path: $!";
}

sub is_symlink ($self, $path) {
  -l $self->path2real($path);
}


my %open_map = (
  r    => O_RDONLY,
  'r+' => O_RDWR,

  w     => O_WRONLY | O_CREAT | O_TRUNC,
  wx    => O_WRONLY | O_CREAT | O_EXCL,
  'w+'  => O_RDWR | O_CREAT | O_TRUNC,
  'wx+' => O_RDWR | O_CREAT | O_EXCL,
  a     => O_WRONLY | O_CREAT | O_APPEND,
  ax    => O_WRONLY | O_CREAT | O_APPEND | O_EXCL,

  'a+'  => O_RDWR | O_CREAT | O_APPEND,
  'ax+' => O_RDWR | O_CREAT | O_APPEND | O_EXCL,
);

sub sysopen ($self, $file, $mode, $perms = undef) {
  croak "Bad mode $mode" unless exists $open_map{$mode};
  &CORE::sysopen($file, $self->path2real($file->path),
    $open_map{$mode}, (defined($perms) ? $perms : ()))
    or croak $file->path . ": $!";
}

sub open ($self, $path, $mode, $perms = undef) {
  my $file = $self->file($path);
  $self->sysopen($file, $mode, $perms);
  $file;
}

sub utimes ($self, $path, $atime = undef, $mtime = undef) {
  my $real = $self->path2real($path);
  utime($atime // undef, $mtime // undef, $real) or croak "utimes $path: $!";
}

sub close ($self, $file) {
  close $file;
}

sub stat ($self, $path) {
  my %opts;
  my @stat = Time::HiRes::stat $self->path2real($path) or croak "stat $path: $!";
  @opts{qw(dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks)} = @stat;
  Evo::Fs::Stat->new(%opts, _data => \@stat);
}

sub rename ($self, $old, $new) {
  rename $self->path2real($old), $self->path2real($new) or croak "rename $!";
}


my %seek_map = (start => SEEK_SET, cur => SEEK_CUR, end => SEEK_END,);

sub sysseek ($self, $file, $pos, $whence = 'start') {
  croak "Bad whence $whence" unless exists $seek_map{$whence};
  &CORE::sysseek($file, $pos, $seek_map{$whence}) // croak "Can't sysseek $!";
}

sub syswrite ($, $, $, @) {    # other lengh, scalar offset
  shift;
  &CORE::syswrite(@_) // croak "Can't write: $!";
}

sub sysread ($, $, $, $, @) {    # @other = string offset
  shift;
  &CORE::sysread(@_) // croak "Can't read: $!";
}

sub unlink ($self, $path) {
  unlink $self->path2real($path) or croak "$path $!";
}

sub remove_tree ($self, $path) {
  my $real = $self->path2real($path);
  croak "remove_tree $real: Not a directory" unless $self->stat($path)->is_dir;
  File::Path::remove_tree($real, {error => \my $err});
  croak join('; ', map { $_->%* } @$err) if @$err;    # TODO: test
}

sub ls ($self, $path) {
  my $real = $self->path2real($path);
  opendir(my $dh, $real) || croak "Can't opendir $real: $!";
  my @result = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
  closedir $dh;
  @result;
}

my %flock_map = (
  ex    => LOCK_EX,
  ex_nb => LOCK_EX | LOCK_NB,
  sh    => LOCK_SH,
  sh_nb => LOCK_SH | LOCK_NB,
  un    => LOCK_UN
);


sub flock ($self, $file, $flag) {
  croak "Bad flag $flag" unless exists $flock_map{$flag};
  my $res = flock($file, $flock_map{$flag});
  croak "$!" unless $res || $! == EAGAIN;
  $res;
}


my sub make_dirs ($self, $path) {
  my (undef, $dirs) = fileparse($path);
  $self->make_tree($dirs);
}

# don't copy 3rd arg
sub append_file ($self, $file, $) {
  make_dirs($self, $file->path);
  $self->sysopen($file, 'a');
  $self->flock($file, 'ex');
  $self->syswrite($file, $_[2]);
  $self->flock($file, 'un');
  $file;
}

sub append ($self, $path, $) {
  $self->append_file($self->file($path), $_[2]);
}

# don't copy 3rd arg
sub write_file ($self, $file, $) {
  make_dirs($self, $file->path);
  $self->sysopen($file, 'w');
  $self->flock($file, 'ex');
  $self->syswrite($file, $_[2]);
  $self->flock($file, 'un');
  $file;
}

sub write ($self, $path, $) {
  $self->write_file($self->file($path), $_[2]);
}

sub read_file ($self, $file) {
  $self->sysopen($file, 'r');
  $self->flock($file, 'sh');
  $self->sysread($file, \my $buf, $self->stat($file->path)->size);
  $self->flock($file, 'un');
  $buf;
}

sub read ($self, $path) {
  $self->read_file($self->file($path));
}

sub write_many ($self, %map) {
  $self->write($_, $map{$_}) for keys %map;
  $self;
}

sub find_files ($self, $start, $files_fn, $pick = undef) {
  my %seen;
  my $fn = sub ($path, $stat) {
    return unless $stat->is_file;
    return
      if $seen{$stat->dev, '-',
      $stat->ino}++;    # to avoid messing hardlinks, also works for symlinks
    $files_fn->($self->file($path), $stat);
  };
  $self->traverse($start, $fn, $pick);
}

# make faster?
sub traverse ($self, $start, $fn, $pick_d = undef) {

  $start = [$start] unless ref $start eq 'ARRAY';
  my %seen;             # don't go into the same dir twice

  my @stack = map {
    my $abs  = $self->to_abs($_);
    my $stat = $self->stat($abs);
    $seen{$stat->dev, '-', $stat->ino}++ ? () : [$abs, $stat];
  } $start->@*;

  while (@stack) {
    my ($cur_dir, $cur_dir_stat) = (pop @stack)->@*;

    my (@dirs, @children);
    foreach my $cur_child (sort $self->ls($cur_dir)) {

      my $abs = File::Spec->rel2abs($cur_child, $cur_dir);
      my $stat = $self->stat($abs);

      if ( $stat->is_dir
        && $stat->can_exec
        && $stat->can_read
        && !($seen{$stat->dev, '-', $stat->ino}++)
        && (!$pick_d || $pick_d->($self->dir($abs), $stat)))
      {
        unshift @dirs, [$abs, $stat];
      }
      push @children, [$abs, $stat];

    }
    $fn->($_->@*) for @children;
    push @stack, @dirs;
  }
}

1;

=head1 SYNOPSIS

  use Evo::Fs::Class;
  use Evo;
  my $orig_fs = Evo::Fs::Class->new;
  my $fs      = $orig_fs->cd('/tmp');    # new Fs with cwd as '/tmp'
  $fs->write('a/foo', 'one');
  $fs->append('a/foo', 'two');
  say $fs->read('a/foo');                # onetwo
  say $fs->read('/tmp/a/foo');           # the same, a/foo resolves to /tmp/a/foo

  # bulk
  $fs->write_many('/tmp/a/foo' => 'afoo', '/tmp/b/foo' => 'bfoo');

  my $file = $fs->open('/tmp/c', 'w+');
  $fs->syswrite($file, "123456");
  $fs->sysseek($file, 0);
  $fs->sysread($file, \my $buf, 3);
  say $buf;                              # 123

  $fs->find_files(

    # where to start
    './',

    # do something with file
    sub ($file, $stat) {
      say $file->name;
    },

    # skip dirs like .git
    sub ($dir, $stat) {
      $dir->name !~ /^\./;
    }
  );

  $fs->find_files(
    ['/tmp'],
    sub ($file, $stat) {
      say $file->path;
    }
  );

=head1

Virtual testable mockable FileSystem.
11% slower than simple functions, but benefits worth it

=head2 cd, cdm ($self, $path)

  my $new = $fs->cd('foo/bar');
  say $new->cwd;    # ~/foo/bar
  $new = $fs->cd('foo/bar');
  say $new->cwd;    # ~/foo/bar

Returns new FS with passed C<cwd>

=head2 cdm ($self, $path)

Same as L</cd> but also calls L</make_tree> before

=head2 append_path, write_path

Append or write content to file. Dirs will be created if they don't exist.
Use lock 'ex' during each invocation

=head2 write_many

Write many files using L<write_path>

=head2 read_path

Read the whole file and returns the content. Lock with 'sh' during reading

=head2 sysseek($self, $position, $whence='start')

Whence can be one of:

=for :list
* start
* cur
* end

=head2 read ($self, $file, $ref, $length[, $offset])

Calls C<sysread> but accepts scalar reference for convinience

=head2 write($self, $file, $scalar, $length, $offset)

Calls C<syswrite>

=head2 open ($self, $path, $mode)

  my $file = $fs->open('/tmp/foo', 'r');

Mode can be one of:

=for :list
* r
Open file for reading. An exception occurs if the file does not exist.
* r+
Open file for reading and writing. An exception occurs if the file does not exist

* w
Open file for writing. The file is created (if it does not exist) or truncated (if it exists).
* wx
Like C<w> but fails if path exists.
* w+
Open file for reading and writing. The file is created (if it does not exist) or truncated (if it exists).
* wx+
Like C<w+> but fails if path exists.

* a
Open file for appending. The file is created if it does not exist.
* ax
Like C<a> but fails if path exists.
* a+
Open file for reading and appending. The file is created if it does not exist.
* ax+
Like C<a+> but fails if path exists.

=head2 rename($self, $oldpath, $newpath)

Rename a file. Doesn't change opened paths of files (because right now doesn't register them, but in the future this may be changed).

=head2 stat($self, $path)

Return a L<Evo::Fs::Stat> object

=head2 to_abs

  my $fs = Evo::Fs::Base->new(cwd => '/foo');
  say $fs->to_abs('bar');    # /foo/bar

Convert relative path to absolute, depending on L</cwd> attribute.
This is virtual represantion only and L</root> doesn't affects the value

=head2 cwd

Current working directory which affects relative paths. Should be absolute.

=head2 root

Can be used like a chroot in Linux. Should be absolute

=head2 path2real($virtual)

Convert a virtual path to the real one.

=head2 find_files($self, $dirs, $fn, $pick=undef)

  $fs->find_files('./tmp', sub ($file, $stat) {...}, sub ($dir, $stat) {...});
  $fs->find_files(['/tmp'], sub ($file, $stat) {...});

Find files in given directories. You can skip some directories by providing C<$pick-E<gt>($dir, $stat)> function.
This will work ok on circular links, hard links and so on. Every file and it's stat will be passed to C<$fn-E<gt>($file, $stat)>only once
even if it has many links.

So, in situations, when a file have several hard and symbolic links, only one of them will be passed to C<$fn>, and potentially
each time it can be different path for each C<find_files> invocation.

See L</traverse> for examining all nodes. This method just decorate it's arguments

=head2 traverse($self, $dirs, $fn $pick=undef)

Traverse directories and invokes C<$fn-E<gt>$path, $stat> for each child node.
Pay attention, unlike L</find_files>, C<$fn> accepts C<$path>, not C<Evo::Fs::File>
You can provide C<$pick-E<gt>($dir, $stat)> to skip directories.


  $fs->traverse('/tmp', sub ($path, $stat) {...}, sub ($dir, $stat) {...});
  $fs->traverse(['/tmp'], sub ($path, $stat) {...},);

Also this method doesn't try to access directories without X and R permissions or pass them to C<$pick> (but such directories will be passed to C<fn> because are regular nodes)

In most cases you may want to use L</find_files> instead.

=cut
