# perl-classes-benchmark

    cpanm Evo Evo::XS Moo MooX::StrictConstructor Class::XSAccessor Mouse MouseX::StrictConstructor Moose MooseX::StrictConstructor Mojolicious
    perl bench-classes.pl

##results

    Simple accessors
               Rate  Mojo Moose Mouse   Moo   Evo
    Mojo  1953125/s    --   -1%  -51%  -53%  -56%
    Moose 1968504/s    1%    --  -51%  -53%  -56%
    Mouse 4000000/s  105%  103%    --   -4%  -10%
    Moo   4166667/s  113%  112%    4%    --   -6%
    Evo   4424779/s  127%  125%   11%    6%    --
    ----------


    Roundtip
                  Rate My::Moose   My::Moo My::Mouse  My::Mojo   My::Evo
    My::Moose 200401/s        --      -33%      -40%      -51%      -69%
    My::Moo   299401/s       49%        --      -10%      -26%      -54%
    My::Mouse 332226/s       66%       11%        --      -18%      -49%
    My::Mojo  406504/s      103%       36%       22%        --      -38%
    My::Evo   653595/s      226%      118%       97%       61%        --
