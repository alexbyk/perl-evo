BUILD_DIR="/tmp/perl-evo-xs-build"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR && cp -a ./* $BUILD_DIR/ && cd $BUILD_DIR && perl Makefile.PL && make && perl -Iblib/arch -Ilib $@
