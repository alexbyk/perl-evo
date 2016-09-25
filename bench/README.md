# Benchmarks

## Evo::Class

We're benchmarking Moo + Class::XSAccessor, Mouse(which is XS by itself) and Evo (with default C backend).

1) A constructor `new`
2) Simple get/set
3) More complex attributes

    cpanm Evo Moo MooX::StrictConstructor Class::XSAccessor Mouse MouseX::StrictConstructor
    perl bench/bench-classes.pl

### Results (i7-3770)

    New(strict)
            Rate   Moo Mouse   Evo
    Moo    453/s    --  -30%  -73%
    Mouse  645/s   43%    --  -61%
    Evo   1675/s  270%  160%    --


    Simple get+set
               Rate   Moo Mouse   Evo
    Moo   3920956/s    --  -16%  -26%
    Mouse 4647098/s   19%    --  -13%
    Evo   5316295/s   36%   14%    --


    Lazy + default + simple
               Rate   Moo Mouse   Evo
    Moo   1592888/s    --  -27%  -31%
    Mouse 2182991/s   37%    --   -5%
    Evo   2293759/s   44%    5%    --

### Conclusions

Obviously, Mouse and Evo are faster than Moo.

While the performance of attributes is similar, Evo's `new` constructor is significantly faster (2.5-4 times).

Also in perl build with MULTIPLICITY enabled this module is a little bit slower than without it. That's because I don't realy need this feature and try to keep code simple

## Evo::Lib::try

    cpanm Evo Try::Tiny
    perl bench/bench-try.pl

We evaluate simple function `inc_c` that increases some counter and may die

    # Try::Tiny
    try {inc_c} catch {dec_c} finally {dec_c};

    # Evo
    evo_try {inc_c} sub {dec_c}, sub {dec_c};

    # eval
    eval {inc_c};
    my $err;
    if (ref($@) || $@) { $err = $@; dec_c; }
    dec_c;
    die $err if $err;

### Results(XS):

    Try::Tiny      105218/s            --          -95%          -97%
    Evo::Lib::try 1989486/s         1791%            --          -38%
    eval          3185777/s         2928%           60%            --

### Results(PP):

    Try::Tiny      108742/s            --          -86%          -96%
    Evo::Lib::try  771011/s          609%            --          -75%
    eval          3099675/s         2750%          302%            --

### Conclusions

Evo's `try` is about 20 times faster than `Try::Tiny::try` and almost as fast as bare `eval` code, so XS can be used without performance penalty in production
