use Evo 'Test::More; Evo::Internal::Exception; -Fs';
use File::Spec::Functions qw(abs2rel catdir rel2abs);
use File::Temp;


PATH2REAL: {
  my $fs = Evo::Fs->new(cwd => File::Temp->newdir);
  is $fs->path2real('/foo/bar.txt'), rel2abs '/foo/bar.txt';
  is $fs->path2real('foo.txt'), catdir($fs->cwd, 'foo.txt');
}

TO_ABS: {
  my $fs = Evo::Fs->new(cwd => my $cwd = File::Temp->newdir);
  is $fs->to_abs('/baz/'), rel2abs '/baz';
  is $fs->to_abs('baz'), catdir($cwd, 'baz');
}

#BAD_CWD: {
#  my $fs = Evo::Fs->new(cwd => File::Temp->newdir);
#  like exception { Evo::Fs->new(cwd => '/tmp/4042223423path') }, qr/4042223423path.+$0/;
#  like exception { $fs->cd('404') }, qr/404.+$0/;
#}

CD: {
  my $fs = Evo::Fs->new(cwd => File::Temp->newdir);
  $fs->make_tree('foo');
  my $new = $fs->cdm('foo');
  is $fs->path2real('foo'), $new->path2real('.');
}

CDM: {
  my $fs = Evo::Fs->new(cwd => File::Temp->newdir);
  my $new = $fs->cdm('foo');
  ok $fs->stat('foo')->is_dir;
  is $fs->path2real('foo'), $new->path2real('.');
}

done_testing;
