requires 'perl',      '5.22.0';
#recommends 'Evo::XS', '0.006';

on test => sub {
  requires 'Test::More', '0.88';
  requires 'Test::Pod';
};

on 'develop' => sub {
  requires 'Pod::Coverage::TrustPod';
  requires 'Test::Perl::Critic', '1.02';
};
