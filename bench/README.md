# perl-classes-benchmark

    cpanm Evo Evo::XS Moo MooX::StrictConstructor Class::XSAccessor Mouse MouseX::StrictConstructor Moose MooseX::StrictConstructor Mojolicious
    perl bench-classes.pl

##results

    ->new(...) - benchmark object initialization with 3 values
               Rate Moose   Moo Mouse  Mojo   Evo
    Moose  377358/s    --  -36%  -49%  -69%  -77%
    Moo    591716/s   57%    --  -21%  -52%  -64%
    Mouse  746269/s   98%   26%    --  -40%  -54%
    Mojo  1234568/s  227%  109%   65%    --  -25%
    Evo   1639344/s  334%  177%  120%   33%    --



    ->foo('SIMPLE'); ->foo; Simple accessors
               Rate  Mojo Moose   Moo Mouse   Evo
    Mojo  1845018/s    --  -14%  -46%  -54%  -56%
    Moose 2136752/s   16%    --  -38%  -46%  -49%
    Moo   3424658/s   86%   60%    --  -14%  -18%
    Mouse 3968254/s  115%   86%   16%    --   -6%
    Evo   4201681/s  128%   97%   23%    6%    --



    Roundtrip
              Rate Moose   Moo Mouse   Evo
    Moose 197628/s    --  -32%  -35%  -64%
    Moo   292398/s   48%    --   -4%  -46%
    Mouse 303951/s   54%    4%    --  -44%
    Evo   543478/s  175%   86%   79%    --
