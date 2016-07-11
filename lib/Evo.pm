package Evo;
use strict;
use warnings;
use Carp 'croak';
use Module::Load ();
use Evo::Internal::Util;
use Evo::Attr;


my $ARGS_RX    = qr/[\s\(\[]*    ( [^\)\]]*?)    [\s\)\]]*/x;
my $EMPTY_ARGS = qr/\s*\(\s*\)\s*/x;

sub _parse {
  my ($caller, $val) = @_;
  my $orig = $val;
  $val =~ tr/\n/ /;
  $val =~ s/^\s+|\s+$//g;

  $val =~ /^ ((\-|\/?(:{2})?)? $Evo::Internal::Util::RX_PKG_NOT_FIRST*) (.*)$/x;
  croak qq#Can't parse string "$orig"# unless $1;
  my ($class, $args) = (Evo::Internal::Util::resolve_package($caller, $1), $4);

  # ()
  return ($class, 1) if $args =~ $EMPTY_ARGS;

  $args =~ s/^$ARGS_RX$/$1/;
  return ($class, 0) unless $args;

  my @args = split /[,\s]+/, $args;
  ($class, 0, @args);
}

sub import {
  shift;
  my ($target, $filename, $line) = caller;

  Evo::Attr->patch_package($target);

  my @list = @_;
  unshift @list, '-Default' unless grep { $_ && $_ eq '-Default' } @list;

  # trim
  @list = grep {$_} map { my $s = $_; $s =~ s/^\s+|\s+$//g; $s } map { split ';', $_ } @list;
  foreach my $key (@list) {
    my ($src, $empty, @args) = _parse($target, $key);
    Module::Load::load($src);
    next if $empty;
    if (my $import = $src->can('import')) {
      Evo::Internal::Util::inject(
        package  => $target,
        line     => $line,
        filename => $filename,
        code     => $import
      )->($src, @args);
    }
    elsif (@args) {
      croak qq{Got import arguments but "$src" doesn't have an "import" method};
    }
  }
}


# VERSION

1;

# ABSTRACT: Evo - the next generation development framework


=head1 SYNOPSYS

  # enables strict, warnings, utf8, :5.22, signatures, postderef
  use Evo;

=head1 STATE

This module is under active development. It changes often and a lot! Get involved L<https://github.com/alexbyk/perl-evo>

Also there are many gaps in documentation.

=head1 DESCRIPTION

This framework opens a new age of perl programming
It provides rewritten and postmodern features like

=over

=item *
[almost ready] Rewritten sexy L<Evo::Export>

=item *
[almost ready] Post modern code injection programming L<Evo::Class> instead of traditional OO

=item *
[almost ready] Fast non recursive L<Evo::Promise>, 100% "Promise/Spec A" compatible. + Nice syntax via experimental L<Evo::Prm>

=item *
(experimental) Exception handling in pure perl: L<Evo::Eval>, "try catch" alternative. Like C<Try::Tiny>, but without its bugs and much faster

=item *
(experimental) L<Evo::Ee> - a role that provides "EventEmitter" abilities

=item *
(experimental) L<Evo::Fs> - abstraction layer between you app and FileSystem for simple testing

=item *
(experimental, not ready) C<Boa> - new sexy testing framework and runner for both blocking and non-blocking tests (Unit testing + functional testing). 10-100 times faster than traditional C<prove> and has a C<"watch"> mode.

=item *
(not started yet) Base modules for non-blocking client/server programming

=back


=head1 VIM

=for HTML <p><img src="https://raw.github.com/alexbyk/perl-evo/master/demo.gif" alt="Perl Evo gif" /></p>

Vim ultisnips with C<Evo> support can be found here: L<https://github.com/alexbyk/vim-ultisnips-perl>

=head1 IMPORTING

Load Module and call C<import> method, emulating C<caller>.

  use Evo 'Foo';                 # use Foo
  use Evo 'Foo ()';              # use Foo();
  use Evo 'FooClass foo1 foo2';  # use FooClass qw(foo1 foo2);

Used to make package header shorter

  use Evo '-Eval *; My::App';    # use Evo::Eval '*'; use My::App;

All examples above also import C<string; experimental> and other from C<Evo::Default>

=head2 SHORTCUTS

  :: => (append to current)
  /:: => (append to parent)
  - => Evo (append to Evo)

=head2 shortcuts

Shortcuts are used to make life easier during code refactoring (and your module shorter) in L<Evo::Export> and L<Evo::Class/"with">

C<-> is replaced by C<Evo>

  use Evo '-Promise promise'; # "Evo::Promise promise"

C<:> and C<::> depend on the package name where they're used

C<::> means relative to the current module as a child

  package My::App;
  use Evo '::Bar'; # My::App::Bar

C</> means parent and C</::> means it's a sibling module (child of the parent of the current module)

  package My::App;
  use Evo '/::Bar'; # My::Bar

=head1 IMPORTS

With or without options, C<use Evo> loads L<Evo::Default>:

=head2 -Default

  use strict;
  use warnings;
  use feature ':5.22';
  use experimental 'signatures';
  use feature 'postderef';

I have decided that using 5.22 and some of the experimental features it brings has many benefits and is worth it. This list will be expanded in the future, I hope

=head2 -Loaded

This marks inline or generated classes as loaded, so can be used with
C<require> or C<use>. So this code won't die. Used for test and examples in the documentation

  require My::Inline;

  {
    package My::Inline;
    use Evo -Loaded;
    sub foo {'foo'}
  }

=cut
