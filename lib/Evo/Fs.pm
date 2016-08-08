package Evo::Fs;
use Evo '-Export *; -Class; ::Stat; Carp croak';

# ========= MODULE =========

our $SINGLE = __PACKAGE__->new();
sub _FS : Export(FS) {$SINGLE}
META->mark_as_private('_FS');


# ========= CLASS =========

use Fcntl qw(:seek O_RDWR O_RDONLY O_WRONLY O_RDWR O_CREAT O_TRUNC O_APPEND O_EXCL :flock);
use Evo 'File::Spec; File::Path; Cwd() abs_path; File::Basename fileparse; Symbol()';
use Time::HiRes ();
use List::Util 'first';
use Errno qw(EAGAIN EWOULDBLOCK);
use Scalar::Util;

our @CARP_NOT = qw(Evo::Fs::Temp);

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


sub utimes ($self, $path, $atime = undef, $mtime = undef) {
  my $real = $self->path2real($path);
  utime($atime // undef, $mtime // undef, $real) or croak "utimes $path: $!";
}

sub close ($self, $fh) {
  close $fh;
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

# self, fh, path, mode, perm?
sub sysopen ($, $, $, $, @) {
  croak "Bad mode $_[3]" unless exists $open_map{$_[3]};
  &CORE::sysopen($_[1], $_[0]->path2real($_[2]), $open_map{$_[3]}, (defined($_[4]) ? $_[4] : ()))
    or croak "sysopen: $!";
}


sub sysseek ($self, $fh, $pos, $whence = 'start') {
  croak "Bad whence $whence" unless exists $seek_map{$whence};
  &CORE::sysseek($fh, $pos, $seek_map{$whence}) // croak "Can't sysseek $!";
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


sub flock ($self, $fh, $flag) {
  croak "Bad flag $flag" unless exists $flock_map{$flag};
  my $res = flock($fh, $flock_map{$flag});
  croak "$!" unless $res || $! == EAGAIN || $! == EWOULDBLOCK;
  $res;
}

sub open ($self, $path, $mode, @rest) {
  my $fh;

  $self->make_tree((fileparse($path))[1]) unless ($mode eq 'r' && $mode eq 'r+');
  $self->sysopen($fh, $path, $mode, @rest);

  $fh;
}


sub append ($self, $path, $) {
  $self->make_tree((fileparse($path))[1]);
  $self->sysopen(my $fh, $path, 'a');
  $self->flock($fh, 'ex');
  $self->syswrite($fh, $_[2]);
  $self->flock($fh, 'un');
  CORE::close $fh;
  return;
}

# don't copy 3rd arg
sub write ($self, $path, $) {
  $self->make_tree((fileparse($path))[1]);
  $self->sysopen(my $fh, $path, 'w');
  $self->flock($fh, 'ex');
  $self->syswrite($fh, $_[2]);
  $self->flock($fh, 'un');
  CORE::close $fh;
  return;
}

sub read_ref ($self, $path) {
  $self->sysopen(my $fh, $path, 'r');
  $self->flock($fh, 'sh');
  $self->sysread($fh, \my $buf, $self->stat($path)->size);
  $self->flock($fh, 'un');
  CORE::close $fh;
  \$buf;
}

sub read ($self, $path) {
  $self->read_ref($path)->$*;
}

sub write_many ($self, %map) {
  $self->write($_, $map{$_}) for keys %map;
  $self;
}

sub find_files ($self, $start, $fhs_fn, $pick = undef) {
  my %seen;
  my $fn = sub ($path, $stat) {
    return unless $stat->is_file;

    # to avoid messing hardlinks, also works for symlinks
    return if $seen{($^O eq 'MSWin32' ? $path : $stat->dev, '-', $stat->ino)}++;
    $fhs_fn->($path, $stat);
  };
  $self->traverse($start, $fn, $pick);
}

# make faster?
sub traverse ($self, $start, $fn, $pick_d = undef) {

  $start = [$start] unless ref $start eq 'ARRAY';
  my %seen;    # don't go into the same dir twice

  my @stack = map {
    my $abs  = $self->to_abs($_);
    my $stat = $self->stat($abs);
    $seen{($^O eq 'MSWin32' ? $abs : $stat->dev, '-', $stat->ino)}++ ? () : [$abs, $stat];
  } $start->@*;

  while (@stack) {
    my ($cur_dir, $cur_dir_stat) = (pop @stack)->@*;

    my (@dirs, @children);
    foreach my $cur_child (sort $self->ls($cur_dir)) {

      my $abs = File::Spec->rel2abs($cur_child, $cur_dir);
      my $stat = $self->stat($abs);


      my $bool
        = $stat->is_dir
        && $stat->can_exec
        && $stat->can_read
        && ($^O eq 'MSWin32' ? !($seen{$abs}++) : !($seen{$stat->dev, '-', $stat->ino}++))
        && (!$pick_d || $pick_d->($abs, $stat));

      unshift @dirs, [$abs, $stat] if $bool;
      push @children, [$abs, $stat];

    }
    $fn->($_->@*) for @children;
    push @stack, @dirs;
  }
}


1;

=head1 SYNOPSIS

  # single
  use Evo '-Fs FS';
  say FS->ls('./');


  # class
  use Evo '-Fs; File::Basename fileparse';
  my $orig_fs = Evo::Fs->new;
  my $fs      = $orig_fs->cd('/tmp');    # new Fs with cwd as '/tmp'

  my $fh = $fs->open('foo/bar.txt', 'w');    # open and create '/foo' if necessary
  $fs->close($fh);

  $fs->write('a/foo', 'one');
  $fs->append('a/foo', 'two');
  say $fs->read('a/foo');                # onetwo
  say $fs->read('/tmp/a/foo');           # the same, a/foo resolves to /tmp/a/foo
                                         # bulk
                                         

  $fs->write_many('/tmp/a/foo' => 'afoo', '/tmp/b/foo' => 'bfoo');
  $fs->sysopen($fh, '/tmp/c', 'w+');
  $fs->syswrite($fh, "123456");
  $fs->sysseek($fh, 0);
  $fs->sysread($fh, \my $buf, 3);
  say $buf;                              # 123
  $fs->find_files(

    # where to start
    './',

    # do something with file
    sub ($path, $stat) {
      say $path;
    },

    # skip dirs like .git
    sub ($path, $stat) {
      scalar fileparse($path) !~ /^\./;
    }
  );
  $fs->find_files(
    ['/tmp'],
    sub ($path, $stat) {
      say $path;
    }
  );



=head1 DESCRIPTION

An abstraction layer between file system and your application. Provides a nice interface for blocking I/O and other file stuff.

It's worth to use at least because allow you to test FS logic of your app with the help of L<Evo::Fs::Class::Temp>.


Imagine, you have an app that should read C</etc/passwd> and validate a user C<validate_user>. To test this behaviour with traditional IO you should implement C<read_passwd> operation and stub it. With C<Evo::Fs> you can just create a temporary filesystem with C<chroot> like behaviour, fill C</etc/passwd> and inject this as a dependency to you app:


Here is our app. Pay attention it has a C<fs> attribute with default.


  package My::App;
  use Evo '-Fs FS; -Class';

  has fs => sub { FS() };

  sub validate_user ($self, $user) {
    $self->fs->read('/etc/passwd') =~ /$user/;
  }


And here is how we test it

  package main;
  use Evo '-Fs; -Fs::Temp; Test::More';
  my $app = My::App->new(fs => Evo::Fs::Temp->new);    # provide dependency as Evo::Fs::Class::Temp

  # or mock the single object
  local $Evo::Fs::SINGLE = Evo::Fs::Temp->new;
  $app = My::App->new();                               # provide dependency as Evo::Fs::Class::Temp

  $app->fs->write('/etc/passwd', 'alexbyk:x:1:1');
  diag "Root is: " . $app->fs->root;                   # temporary fs has a "root" method

  ok $app->validate_user('alexbyk');
  ok !$app->validate_user('not_existing');

  done_testing;

We created a temporary FileSystem and passed it as C<fs> attribute. Now we can write C</etc/passwd> file in chrooted envirement.
This testing strategy is simple and good.

You can also mock a single object this way

  local $Evo::Fs::SINGLE = Evo::Fs::Temp->new;
  say FS();


=head1 EXPORTS

=head2 FS, $Evo::Fs::SINGLE

Return a single instance of L<Evo::Fs>

=head1 METHODS

=head2 sysopen ($self, $path, $mode, $perm=...)

  my $fh = $fs->open('/foo/bar.txt', 'w');

Open a file and return a filehandle. Create parent directories if necessary.
 See L</sysopen> for list of modes

  

=head2 cd ($self, $path)

  my $new = $fs->cd('foo/bar');
  say $new->cwd;    # ~/foo/bar
  $new = $fs->cd('foo/bar');
  say $new->cwd;    # ~/foo/bar

Returns new FS with passed C<cwd>

=head2 cdm ($self, $path)

Same as L</cd> but also calls L</make_tree> before

=head2 append, write, read, read_ref

  $fs->write('/tmp/my/file', 'foo');
  $fs->append('/tmp/my/file', 'bar');
  say $fs->read('/tmp/my/file');            # foobar
  say $fs->read_ref('/tmp/my/file')->$*;    # foobar

Read, write or append a content to the file. Dirs will be created if they don't exist.
Use lock 'ex' for append and write and lock 'sh' for read during each invocation

=head2 write_many

Write many files using L<write>

=head2 sysseek($self, $position, $whence='start')

Whence can be one of:

=for :list
* start
* cur
* end


=head2 sysread ($self, $fh, $ref, $length[, $offset])

Call C<sysread> but accepts scalar reference for convinience

=head2 syswrite($self, $fh, $scalar, $length, $offset)

Call C<syswrite>

=head2 sysopen ($self, $fh, $path, $mode, $perm=...)

  $fs->sysopen(my $fh, '/tmp/foo', 'r');

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

Rename a file.

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

  $fs->find_files('./tmp', sub ($fh, $stat) {...}, sub ($dir, $stat) {...});
  $fs->find_files(['/tmp'], sub ($fh, $stat) {...});

Find files in given directories. You can skip some directories by providing C<$pick-E<gt>($dir, $stat)> function.
This will work ok on circular links, hard links and so on. Every file and it's stat will be passed to C<$fn-E<gt>($fh, $stat)>only once
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
