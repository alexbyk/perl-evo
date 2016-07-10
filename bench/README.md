# perl-classes-benchmark

    cpanm Evo Evo::XS Moo MooX::StrictConstructor Class::XSAccessor Mouse MouseX::StrictConstructor Moose MooseX::StrictConstructor Mojolicious
    perl bench-classes.pl

##results

    ->new(...) - benchmark object initialization with 3 values
               Rate Moose   Moo Mouse  Mojo   Evo
    Moose  373134/s    --  -33%  -51%  -69%  -79%
    Moo    555556/s   49%    --  -27%  -54%  -69%
    Mouse  763359/s  105%   37%    --  -37%  -58%
    Mojo  1219512/s  227%  120%   60%    --  -33%
    Evo   1818182/s  387%  227%  138%   49%    --



    ->foo('SIMPLE'); ->foo; Simple accessors
               Rate  Mojo Moose   Moo Mouse   Evo
    Mojo  1908397/s    --   -6%  -48%  -50%  -56%
    Moose 2040816/s    7%    --  -45%  -46%  -53%
    Moo   3703704/s   94%   81%    --   -2%  -15%
    Mouse 3787879/s   98%   86%    2%    --  -13%
    Evo   4347826/s  128%  113%   17%   15%    --



    Roundtrip
              Rate Moose   Moo Mouse   Evo
    Moose 202020/s    --  -34%  -42%  -70%
    Moo   306748/s   52%    --  -12%  -55%
    Mouse 348432/s   72%   14%    --  -49%
    Evo   680272/s  237%  122%   95%    --
