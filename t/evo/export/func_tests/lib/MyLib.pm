package MyLib;
use Evo '-Export *';

# export under another name
export('foo:fooa1');


# exotic case, just to be consistent
BEGIN {
  no warnings 'once';
  *fooa2 = *foo;
}

# export by default name, glob alias will be found too
sub foo : Export {'FOO'}

# export by aliases
sub bar : Export(bara1) Export(bara2) {'BAR'}


# export anon sub
my $anon = sub : Export(noname) {'noname'};

1;
