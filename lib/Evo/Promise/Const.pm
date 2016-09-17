package Evo::Promise::Const;
use Evo '-Export *';

use constant {PENDING => 'PENDING', REJECTED => 'REJECTED', FULFILLED => 'FULFILLED'};

export qw(PENDING REJECTED FULFILLED);

1;
