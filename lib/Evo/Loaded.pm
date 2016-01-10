package Evo::Loaded;
use Evo;
use Module::Loaded;

sub import { mark_as_loaded(scalar caller) }

1;

=head1 SYNOPSYS

  package main;
  use Evo;

  {

    package Bar;
    use Evo -Loaded;
  };

  # now use can use this without "Can't find module..."
  use Bar;


=head1 DESCRIPTION

Mark module as loaded. Mostly for tests and examples in the docs, to be able for you just copy-paste-run

If you write several packages in one file and try to C<use> them

  package main;
  use Evo;
  {
    package Foo;
    use Evo;

    package Bar;
    use Evo -Loaded;
  }

  use Bar;
  use Foo;

You'll get "Can't locate Foo.pm in @INC" at C<use Foo>. That's because perl tries to load module. C<use Bar> doesn't causes the error because marked as loaded.

So if you see this in examples, you can safely remove it from the real code, if you put package C<Bar> in the separate C<Bar.pm> file

=cut
