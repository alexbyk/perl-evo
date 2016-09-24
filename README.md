# Evo - the next generation component-oriented development framework [![Build Status](https://travis-ci.org/alexbyk/perl-evo.svg?branch=master)](https://travis-ci.org/alexbyk/perl-evo)

# INSTALLATION

    cpanm Evo

This module ships with optional C parts for performance. You can avoid installing them by providing PUREPERL_ONLY environmental variable

    PUREPERL_ONLY=1 cpanm Evo


# DESCRIPTION

This framework opens new age of perl programming
It provides rewritten and postmodern features like

- Rewritten sexy [Evo::Export](https://metacpan.org/pod/Evo::Export)
- [Evo::Fs](https://metacpan.org/pod/Evo::Fs) - abstraction layer between you app and FileSystem for simple testing
- [Evo::Class](https://metacpan.org/pod/Evo::Class) - Post modern object oriented programming with code injections instead of traditional OO. Has a fast XS backend. See [Benchmarks](https://github.com/alexbyk/perl-evo/tree/master/bench)
- Fast non recursive [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise), 100% Promises/Spec A compatible.
- Exception handling in pure perl: [Evo::Lib::try](https://metacpan.org/pod/Evo::Lib#try), like "try catch" but the perl way.
- [Evo::Ee](https://metacpan.org/pod/Evo::Ee) - a class role that gives your component "EventEmitter" abilities

![GIF Demo](https://raw.github.com/alexbyk/perl-evo/master/demo.gif)

Vim ultisnips with `Evo` support can be found here: [vim-ultisnips-perl](https://github.com/alexbyk/vim-ultisnips-perl)

## AUTHOR

alexbyk.com

## COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
