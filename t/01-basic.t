use v6;
use Test;
use lib 'lib';
use Shell::Command;
use Pod::Coverage;

plan 8;

use LibraryMake;

ok True, "Can load module";

my %vars = get-vars('.');
ok %vars<CC>:exists, "Can get vars";

process-makefile('t', %vars);
ok True, "Process makefile didn't die";
ok ("t/Makefile".IO ~~ :f), "Makefile was created";

chdir("t");
shell(%vars<MAKE>);
ok (("test"~%vars<O>).IO ~~ :f), "Object file created";
ok (("test"~%vars<EXE>).IO ~~ :f), "Binary was created";

ok qqx/.{$*SPEC.dir-sep}test%vars<EXE>/ ~~ /^Hello ' ' world\!\n$/, "Binary runs!";

my $p = Pod::Coverage::Full.new;
$p.parse(LibraryMake);
ok !$p.are-missing, 'Everything is documented';
