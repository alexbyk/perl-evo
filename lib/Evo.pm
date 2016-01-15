package Evo;
use strict;
use warnings;
use Carp 'croak';
use Module::Load 'load';
use Evo::Util;
use feature 'say';


my $ARGS_RX = qr/[\s\(\[]*    ( [^\)\]]*?)    [\s\)\]]*/x;

sub _parse {
  my ($caller, $val) = @_;
  my $orig = $val;
  $val =~ tr/\n/ /;
  $val =~ s/^\s+|\s+$//g;

  $val =~ /^ ((\-|\:\:|\:)? $Evo::Util::RX_PKG_NOT_FIRST*) (.*)$/x;
  croak qq#Can't parse string "$orig"# unless $1;
  my ($class, $args) = (Evo::Util::resolve_package($caller, $1), $3);

  $args =~ s/^$ARGS_RX$/$1/;
  return ($class) unless $args;

  my @args = split /[,\s]+/, $args;
  ($class, @args);
}

sub import {
  shift;
  my ($target, $filename, $line) = caller;
  my @list = @_;
  unshift @list, '-Default' unless grep { $_ && $_ eq '-Default' } @list;

  # trim
  @list = grep {$_} map { my $s = $_; $s =~ s/^\s+|\s+$//g; $s } map { split ';', $_ } @list;
  foreach my $key (@list) {
    my ($class, @args) = _parse($target, $key);
    load($class);
    if (my $import = $class->can('import')) {
      Evo::Util::inject(package => $target, line => $line, filename => $filename, code => $import)
        ->($class, @args);
    }
    elsif (@args) {
      croak qq#Got import arguments but $class hasn't "import" method#;
    }
  }
}


# VERSION

1;

# ABSTRACT: Evo - the next generation component-oriented development framework

=head1 SYNOPSYS

  # enables strict, warnings, utf8, :5.22, signatured, postderef
  use Evo;


=head1 DESCRIPTION

This framowerk opens new age of perl programming
It provides rewritten and postmodern features like

=over

=item *
Rewritten sexy L<Evo::Export>

=item *
Post modern component oriented programming L<Evo::Comp> instead of OO

=item *
(no docs yet) Fast Event-Loop L<Evo::Loop> with unique feature zones (Not ready)

=item *
(no docs yet) Fast non recursive L<Evo::Promises>, 100% Promises/Spec A compatible

=item *
Interesting L<Evo::Realm> design pattern, which is as handy as "Singleton" but without Sintleton's flaws. Testable and mockable alternative of the global class

=item *
Exception handling in pure perl: L<Evo::Eval>, "try catch" alternative. Like C<Try::Tiny>, but without it's bugs and much faster

=item *
L<Evo::Ee> - a component role that gives your component "EventEmitter" abilities

=back

=head1 IMPORTING

Load Module and call it's C<import> method, emulating C<caller>. 

  use Evo 'Evo::SomeComp';
  use Evo 'Evo::SomeComp(function)';
  use Evo 'Evo::SomeComp(function,otherfunc)';
  use Evo 'Evo::SomeComp function1 function2';

Used to make package header shorter

  use Evo '-Eval *; My::App';


=head2 SHORTCUTS

  : => . (append to current)
  :: => .. (append to parent)
  - => Evo (append to Evo)

=head2 shortcuts

Shortcuts are used to make life easily during code refactoring (and you module shorter) in L<Evo::Export> and L<Evo::Comp/"with">

C<-> is replaced by C<Evo>

  use Evo '-Promises promise'; # "Evo::Promises promise"

C<:> and C<::> make sense in the package and depends on the package name where is used

C<:> means relative to the current module as a child

  package My::App;
  use Evo ':Bar'; # My::App::Bar

C<::> means as sibling (child of the parent of the current module)

  package My::App;
  use Evo '::Bar'; # My::Bar

=head1 IMPORTS

With or without options, C<use Evo> loads L<Evo::Default>:

=head2 -Default

  use strict;
  use warnings;
  use feature ':5.22';
  use experimental 'signatures';
  use feature 'postderef';

I make some test and decided that using 5.22 and experimental features brings many benefits and worth it. This list will be expanded in the future, I hope

=head2 -Loaded

This marks inline or generated classes as loaded, so can be used with
C<require> or C<use>. So this code won't die

  require My::Inline;

  {
    package My::Inline;
    use Evo -Loaded;
    sub foo {'foo'}
  }

=cut
