use Evo '-Class::T *; Test::More; Test::Fatal';


like exception { t_enum() }, qr/empty.+$0/;

# undefined
my $check_undef = t_enum(undef);
ok $check_undef->(undef);
ok !$check_undef->("");
ok !$check_undef->("ok");


my $check = t_enum(0, "ok", "");

# exists
ok $check->(0);
ok $check->("ok");
ok $check->("");

# false
ok !$check->(undef);
ok !$check->(33);

done_testing;
