package Evo;
use strict;
use warnings;
use Carp 'croak';
use Module::Load 'load';
use Evo::Lib::Bare;
use Evo::Export::Class;
use feature 'say';


my $ARGS_RX    = qr/[\s\(\[]*    ( [^\)\]]*?)    [\s\)\]]*/x;
my $EMPTY_ARGS = qr/\s*\(\s*\)\s*/x;

sub _parse {
  my ($caller, $val) = @_;
  my $orig = $val;
  $val =~ tr/\n/ /;
  $val =~ s/^\s+|\s+$//g;

  $val =~ /^ ((\-|\/?(:{2})?)? $Evo::Lib::Bare::RX_PKG_NOT_FIRST*) (.*)$/x;
  croak qq#Can't parse string "$orig"# unless $1;
  my ($class, $args) = (Evo::Lib::Bare::resolve_package($caller, $1), $4);

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
  my @list = @_;
  unshift @list, '-Default' unless grep { $_ && $_ eq '-Default' } @list;

  # trim
  @list = grep {$_} map { my $s = $_; $s =~ s/^\s+|\s+$//g; $s } map { split ';', $_ } @list;
  foreach my $key (@list) {
    my ($src, $empty, @args) = _parse($target, $key);
    load($src);
    next if $empty;
    if (my $import = $src->can('import')) {
      Evo::Lib::Bare::inject(
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

This module is under active development. It changes often and a lot! Don't use in production. Get involved L<https://github.com/alexbyk/perl-evo>

=head1 DESCRIPTION

This framework opens new age of perl programming
It provides rewritten and postmodern features like

=over

=item *
Rewritten sexy L<Evo::Export>

=item *
Post modern code injection programming L<Evo::Class> instead of traditional OO

=item *
(no docs yet) Fast Event-Loop L<Evo::Loop> with unique feature zones (Not ready)

=item *
Fast non recursive L<Evo::Promise>, 100% "Promise/Spec A" compatible. + Nice syntax via experimental L<Evo::Prm>

=item *
Exception handling in pure perl: L<Evo::Eval>, "try catch" alternative. Like C<Try::Tiny>, but without its bugs and much faster

=item *
L<Evo::Ee> - a class role that gives your "EventEmitter" abilities

=back


=head1 VIM

=for HTML <p><img src="https://raw.github.com/alexbyk/perl-evo/master/demo.gif" alt="Perl Evo gif" /></p>

Vim ultisnips with C<Evo> support can be found here: L<https://github.com/alexbyk/vim-ultisnips-perl>

=head1 IMPORTING

Load Module and call itss C<import> method, emulating C<caller>.

  use Evo 'Evo::SomeClass';
  use Evo 'Evo::SomeClass(function)';
  use Evo 'Evo::SomeClass(function,otherfunc)';
  use Evo 'Evo::SomeClass function1 function2';

Used to make package header shorter

  use Evo '-Eval *; My::App';


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
