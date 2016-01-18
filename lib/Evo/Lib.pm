package Evo::Lib;
use Evo '-Export *; -Io::Handle; -Io::Socket';

no warnings 'once';
*open_nb      = *Evo::Io::Handle::open_nb;
*open_nb_anon = *Evo::Io::Handle::open_nb_anon;
*socket_open_nb  = *Evo::Io::Socket::socket_open_nb;

export qw(socket_open_nb open_nb open_nb_anon);
export_proxy ':Internal', 'ws_combine';


1;
