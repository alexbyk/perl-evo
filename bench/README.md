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

### Results:

                      Rate     Try::Tiny Evo::Lib::try
    Try::Tiny     111348/s            --          -88%
    Evo::Lib::try 919803/s          726%            --
