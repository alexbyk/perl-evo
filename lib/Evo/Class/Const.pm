package Evo::Class::Const;
use Evo '-Export *';

use constant {
  A_RELAXED => 0, A_DEFAULT => 1, A_DEFAULT_CODE => 2, A_REQUIRED => 3, A_LAZY => 4,
  I_NAME => 0, I_TYPE => 1, I_VALUE => 2, I_RO => 4, I_CHECK => 3,
};

export qw(
A_RELAXED A_DEFAULT A_DEFAULT_CODE A_REQUIRED A_LAZY
I_NAME I_TYPE I_RO I_CHECK I_VALUE
);

1;
