# NAME

Evo - Evo - the next generation component-oriented development framework

# VERSION

version 0.001

# DESCRIPTION

This framowerk opens new age of perl programming
It provides rewritten and postmodern features like

- Rewritten sexy [Evo::Export](https://metacpan.org/pod/Evo::Export)
- Post modern component oriented programming [Evo::Comp](https://metacpan.org/pod/Evo::Comp) instead of OO
- (no docs yet) Fast Event-Loop [Evo::Loop](https://metacpan.org/pod/Evo::Loop) with unique feature zones (Not ready)
- (no docs yet) Fast non recursive [Evo::Promises](https://metacpan.org/pod/Evo::Promises), 100% Promises/Spec A compatible
- (no docs yet) Interesting [Evo::Realm](https://metacpan.org/pod/Evo::Realm) design pattern, which is as handy as "Singleton" but without Sintleton's flaws.
It makes real thing that are considered impossible in other languages. For example, testing EventLoop timers without patching, separating flows for one loop and so on.
(ready but experimental and not documented)
- Exception handling in pure perl: [Evo::Eval](https://metacpan.org/pod/Evo::Eval), "try catch" alternative. Like `Try::Tiny`, but without it's bugs and much faster
- [Evo::Ee](https://metacpan.org/pod/Evo::Ee) - a component role that gives your component "EventEmitter" abilities

# SYNOPSYS

    # enables strict, warnings, utf8, :5.22, signatured, postderef
    use Evo;

# IMPORTING

Load Module and call it's `import` method, emulating `caller`. 

    use Evo 'Evo::SomeComp';
    use Evo 'Evo::SomeComp(function)';
    use Evo 'Evo::SomeComp(function,otherfunc)';
    use Evo 'Evo::SomeComp function1 function2';

Used to make package header shorter

    use Evo '-Eval *; My::App';

## SHORTCUTS

    : => . (append to current)
    :: => .. (append to parent)
    - => Evo (append to Evo)

## shortcuts

Shortcuts are used to make life easily during code refactoring (and you module shorter) in [Evo::Export](https://metacpan.org/pod/Evo::Export) and ["with" in Evo::Comp](https://metacpan.org/pod/Evo::Comp#with)

`-` is replaced by `Evo`

    use Evo '-Promises promise';

`:` and `::` make sense in the package and depends on the package name where is used

`:` means relative to the current module as a child

    package My::App;
    use Evo ':Bar'; # My::App::Bar

`::` means as sibling (child of the parent of the current module)

    package My::App;
    use Evo '::Bar'; # My::Bar

# IMPORTS

With or without options, `use Evo` loads [Evo::Default](https://metacpan.org/pod/Evo::Default):

## -Default

    use strict;
    use warnings;
    use feature ':5.22';
    use experimental 'signatures';
    use feature 'postderef';

I make some test and decided that using 5.22 and experimental features brings many benefits and worth it. This list will be expanded in the future, I hope

## -Loaded

This marks inline or generated classes as loaded, so can be used with
`require` or `use`. So this code won't die

    require My::Inline;

    {
      package My::Inline;
      use Evo -Loaded;
      sub foo {'foo'}
    }

# AUTHOR

alexbyk.com

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
