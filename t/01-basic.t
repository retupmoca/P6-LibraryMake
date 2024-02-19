use Test;

use LibraryMake;

constant FLAG = "-fPIC";
%*ENV<LDFLAGS> = FLAG;
my %vars = get-vars('.');

subtest "Sanity checks", {
    ok %vars<CC>:exists, "Can get vars";
    ok (%vars<LDFLAGS> eq FLAG), "ENV overrides VM defaults";
}

subtest "Can create Makefile", {
    if build-tools-installed() {
        lives-ok { process-makefile('t', %vars) }, "Process makefile didn't die";
        ok ("t/Makefile".IO ~~ :f), "Makefile was created";
        chdir("t");
        my $make-output = shell(%vars<MAKE>, :out, :err);
        is $make-output.err.slurp(:close), "";
        ok (("test" ~ %vars<O>).IO ~~ :f), "Object file created";
        ok (("test" ~ %vars<EXE>).IO ~~ :f), "Binary was created";
        ok qqx/.{ $*SPEC.dir-sep }test%vars<EXE>/ ~~ /^Hello ' ' world\!\n$/,
                "Binary runs!";
    }
    else {
        skip
        "Build tools are not installed (CC:%vars<CC>, LD:%vars<LD>, MAKE:%vars<MAKE>)",
        5;
    }
}

if ( !$*DISTRO.is-win && $*DISTRO.name ne "macos") {
    warn $*DISTRO.name;
    subtest "Errors correctly if it can't", {
        my $this-dir = ".".IO;
        my $keep-mode = $this-dir.mode;
        $this-dir.chmod: 0x555;
        throws-like { process-makefile('t', %vars) }, X::AdHoc;
        $this-dir.chmod: $keep-mode;
    }
}

 for <test test.o> {
     $_.IO.unlink;
 }
 "Makefile".IO.unlink;

done-testing;
