use Evo 'Test::More; -Lib *';


is \&open_nb,      Evo::Io::Handle->can('open_nb');
is \&open_nb_anon, Evo::Io::Handle->can('open_nb_anon');
is \&socket_open_nb,  Evo::Io::Socket->can('socket_open_nb');

done_testing;
