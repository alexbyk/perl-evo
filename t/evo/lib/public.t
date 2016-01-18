use Evo 'Test::More; -Lib *';


is \&open_nb,      Evo::Io::Handle->can('open_nb');
is \&open_anon_nb, Evo::Io::Handle->can('open_anon_nb');
is \&socket_open,  Evo::Io::Socket->can('socket_open');

done_testing;
