package Evo::Fs;
use Evo '-Export *; ::Class; ::Class::Temp';

our $SINGLE = Evo::Fs::Class->new();
sub fs() : Export      {$SINGLE}
sub fs_temp() : Export { Evo::Fs::Class::Temp->new }


1;

=head1 SYNOPSIS

  use Evo '-Fs fs';
  say fs->ls('./');

=head1 DESCRIPTION

An abstraction layer between file system and your application. Provides a nice interface for blocking I/O and other file stuff.

It's worth to use at least because allow you to test FS logic of your app with the help of L<Evo::Fs::Class::Temp>.


Imagine, you have an app that should read C</etc/passwd> and validate a user C<validate_user>. To test this behaviour with traditional IO you should implement C<read_passwd> operation and stub it. With C<Evo::Fs> you can just create a temporary filesystem with C<chroot> like behaviour, fill C</etc/passwd> and inject this as a dependency to you app:


Here is our app. Pay attention it has a C<fs> attribute with default.


  package My::App;
  use Evo '-Fs fs:realfs; -Class';

  has fs => sub { realfs() };

  sub validate_user ($self, $user) {
    $self->fs->read('/etc/passwd') =~ /$user/;
  }


And here is how we test it

  package main;
  use Evo '-Fs fs_temp; Test::More';
  my $app = My::App->new(fs => fs_temp());    # mock fs with instance of Evo::Fs::Class::Temp

  $app->fs->write('/etc/passwd', 'alexbyk:x:1:1');
  diag "Root is: " . $app->fs->root;          # temporary fs has a "root" method

  ok $app->validate_user('alexbyk');
  ok !$app->validate_user('not_existing');

  done_testing;

We created a temporary FileSystem and passed it as C<fs> attribute. Now we can write C</etc/passwd> file in chrooted envirement.
This testing strategy is simple and good.

See more documentation in L<Evo::Fs::Class>


=head1 FUNCTIONS

=head2 fs

Return a single instance of L<Evo::Fs::Class>, the same as C<$Evo::Fs::SINGLE>

=head2 fs_temp

Build and return an instance of L<Evo::Fs::Class::Temp>

=cut
