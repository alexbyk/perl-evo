use Evo 'Test::More; Test::Fatal; -Class::Common meta_of';


ok !meta_of("My::Class");
ok meta_of("My::Class", "META");

like exception { ok meta_of("My::Class", "META"); }, qr/My::Class already/;

is meta_of("My::Class"), "META";

done_testing;
