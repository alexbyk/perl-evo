# perl-classes-benchmark

    cpanm Evo Evo::XS Moo MooX::StrictConstructor Class::XSAccessor Mouse MouseX::StrictConstructor Moose MooseX::StrictConstructor Mojolicious
    perl bench-classes.pl

##results

    Simple accessors
               Rate  Mojo Moose   Moo Mouse   Evo
    Mojo  2024291/s    --   -5%  -43%  -52%  -54%
    Moose 2127660/s    5%    --  -40%  -49%  -52%
    Moo   3571429/s   76%   68%    --  -15%  -19%
    Mouse 4201681/s  108%   97%   18%    --   -5%
    Evo   4424779/s  119%  108%   24%    5%    --
    ----------
  
  
    Roundtip
                  Rate My::Moose   My::Moo My::Mouse  My::Mojo   My::Evo
    My::Moose 204082/s        --      -33%      -40%      -51%      -70%
    My::Moo   304878/s       49%        --      -10%      -27%      -55%
    My::Mouse 337838/s       66%       11%        --      -19%      -50%
    My::Mojo  416667/s      104%       37%       23%        --      -38%
    My::Evo   675676/s      231%      122%      100%       62%        --
