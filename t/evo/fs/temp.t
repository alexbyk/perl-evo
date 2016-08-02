use Evo 'Test::More; Evo::Internal::Exception; -Fs::Temp';
use File::Spec::Functions 'catdir';
use File::Temp;


BAD_CD: {
  my $fs = Evo::Fs::Temp->new();
  like exception { $fs->cd('404') }, qr/404.+$0/;
}

CD: {
  my $fs = Evo::Fs::Temp->new();
  $fs->make_tree('foo');
  my $new = $fs->cdm('foo');
  ok $fs->stat('foo')->is_dir;
  is $new->root, $fs->root;
  is $fs->path2real('foo'), $new->path2real('.');
}

CDM: {
  my $fs  = Evo::Fs::Temp->new();
  my $new = $fs->cdm('foo');
  ok $fs->stat('foo')->is_dir;
  is $fs->path2real('foo'), $new->path2real('.');
}

done_testing;
