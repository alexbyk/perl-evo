package Evo::Lib;
use Evo '-Export *; -Io::Handle; -Io::Socket';

no warnings 'once';
*open_nb      = *Evo::Io::Handle::open_nb;
*open_anon_nb = *Evo::Io::Handle::open_anon_nb;
*socket_open  = *Evo::Io::Socket::socket_open;

export qw(socket_open open_nb open_anon_nb);
export_proxy ':Internal', 'ws_combine';


1;
