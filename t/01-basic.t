use v6;
use Test;
use Shell::Command;

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
        shell(%vars<MAKE>);
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

subtest "Errors correctly if it can't", {
    shell "chmod -w .";
    throws-like { process-makefile('t', %vars ) }, X::AdHoc;
    shell "chmod +w .";
}

done-testing;
