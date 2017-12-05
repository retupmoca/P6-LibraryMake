#| An attempt to simplify building native code for a perl6 module.
unit module LibraryMake;

=begin pod
This is effectively a small configure script for a Makefile. It will allow you to
use the same tools to build your native code that were used to build perl6 itself.

Typically, this will be used in both Build.pm (to support installation using a
module manager), and in a standalone Configure.pl script in the src directory
(to support standalone testing/building). Note that if you need additional
custom configure code, you will currently need to add it to both your Build.pm
and to your Configure.pl6

=end pod

=head2 Example Usage

=begin pod
The below files are examples of what you would write in your own project.
The src directory is merely a convention, and the Makefile.in will likely be
significantly different in your own project.

/Build.pm

    use v6;
    use LibraryMake;
    use Shell::Command;

    my $libname = 'chelper';

    class Build {
        method build($dir) {
            my %vars = get-vars($dir);
            %vars{$libname} = $*VM.platform-library-name($libname.IO);
            mkdir "$dir/resources" unless "$dir/resources".IO.e;
            mkdir "$dir/resources/libraries" unless "$dir/resources/libraries".IO.e;
            process-makefile($dir, %vars);
            my $goback = $*CWD;
            chdir($dir);
            shell(%vars<MAKE>);
            chdir($goback);
        }
    }

/src/Configure.pl6

    #!/usr/bin/env perl6
    use v6;
    use LibraryMake;

    my $libname = 'chelper';
    my %vars = get-vars('.');
    %vars{$libname} = $*VM.platform-library-name($libname.IO);
    mkdir "resources" unless "resources".IO.e;
    mkdir "resources/libraries" unless "resources/libraries".IO.e;
    process-makefile('.', %vars);
    shell(%vars<MAKE>);

    say "Configure completed! You can now run '%vars<MAKE>' to build lib$libname.";

/src/Makefile.in (Make sure you use TABs and not spaces!)

    .PHONY: clean test

    all: %DESTDIR%/resources/libraries/%chelper%

    clean:
        -rm %DESTDIR%/resources/libraries/%chelper% %DESTDIR%/*.o

    %DESTDIR%/resources/libraries/%chelper%: chelper%O%
        %LD% %LDSHARED% %LDFLAGS% %LIBS% %LDOUT%%DESTDIR%/resources/libraries/%chelper% chelper%O%

    chelper%O%: src/chelper.c
        %CC% -c %CCSHARED% %CCFLAGS% %CCOUT% chelper%O% src/chelper.c

    test: all
    prove -e "perl6 -Ilib" t

/lib/My/Module.pm6

    # ...

    use NativeCall;
    use LibraryMake;

    constant CHELPER = %?RESOURCES<libraries/chelper>.absolute;

    sub foo() is native( CHELPER ) { * };

/META6.json

    # include the following section in your META6.json:
    "resources" : [
        "library/chelper"
    ],
    "depends" : [
        "LibraryMake"
    ]

=end pod

=head2 Functions

#| Returns configuration variables. Effectively just a wrapper around $*VM.config,
#| as the VM config variables are different for each backend VM.
our sub get-vars(Str $destfolder --> Hash) is export {
    my %vars;
    %vars<DESTDIR> = $destfolder;
    if $*VM.name eq 'parrot' {
        %vars<O> = $*VM.config<o>;
        %vars<SO> = $*VM.config<load_ext>;
        %vars<CC> = $*VM.config<cc>;
        %vars<CCSHARED> = $*VM.config<cc_shared>;
        %vars<CCOUT> = $*VM.config<cc_o_out>;
        %vars<CCFLAGS> = $*VM.config<ccflags>;

        %vars<LD> = $*VM.config<ld>;
        %vars<LDSHARED> = $*VM.config<ld_load_flags>;
        %vars<LDFLAGS> = $*VM.config<ldflags>;
        %vars<LIBS> = $*VM.config<libs>;
        %vars<LDOUT> = $*VM.config<ld_out>;

        %vars<MAKE> = $*VM.config<make>;

        %vars<LDUSR> = '-l';
        # this is copied from moar - probably wrong
        #die "Don't know how to get platform independent '-l' (LDUSR) on Parrot";
        #my $ldusr = $*VM.config<ldusr>;
        #$ldusr ~~ s/\%s//;
        #%vars<LDUSR> = $ldusr;

        %vars<EXE> = $*VM.config<exe>;
    }
    elsif $*VM.name eq 'moar' {
        %vars<O> = $*VM.config<obj>;
        my $so = $*VM.config<dll>;
        $so ~~ s/^.*\%s//;
        %vars<SO> = $so;
        %vars<CC> = $*VM.config<cc>;
        %vars<CCSHARED> = $*VM.config<ccshared>;
        %vars<CCOUT> = $*VM.config<ccout>;
        %vars<CCFLAGS> = $*VM.config<cflags>;

        %vars<LD> = $*VM.config<ld>;
        %vars<LDSHARED> = $*VM.config<ldshared>;
        %vars<LDFLAGS> = $*VM.config<ldflags>;
        %vars<LIBS> = $*VM.config<ldlibs>;
        %vars<LDOUT> = $*VM.config<ldout>;
        my $ldusr = $*VM.config<ldusr>;
        $ldusr ~~ s/\%s//;
        %vars<LDUSR> = $ldusr;

        %vars<MAKE> = $*VM.config<make>;

        %vars<EXE> = $*VM.config<exe>;
    }
    elsif $*VM.name eq 'jvm' {
        %vars<O> = $*VM.config<nativecall.o>;
        %vars<SO> = '.' ~ $*VM.config<nativecall.so>;
        %vars<CC> = $*VM.config<nativecall.cc>;
        %vars<CCSHARED> = $*VM.config<nativecall.ccdlflags>;
        %vars<CCOUT> = "-o"; # this looks wrong?
        %vars<CCFLAGS> = $*VM.config<nativecall.ccflags>;

        %vars<LD> = $*VM.config<nativecall.ld>;
        %vars<LDSHARED> = $*VM.config<nativecall.lddlflags>;
        %vars<LDFLAGS> = $*VM.config<nativecall.ldflags>;
        %vars<LIBS> = $*VM.config<nativecall.perllibs>;
        %vars<LDOUT> = $*VM.config<nativecall.ldout>;

        %vars<MAKE> = 'make';

        %vars<LDUSR> = '-l';
        # this is copied from moar - probably wrong
        #die "Don't know how to get platform independent '-l' (LDUSR) on JVM";
        #my $ldusr = $*VM.config<ldusr>;
        #$ldusr ~~ s/\%s//;
        #%vars<LDUSR> = $ldusr;

        %vars<EXE> = $*VM.config<exe>;
    }
    else {
        die "Unknown VM; don't know how to build";
    }

    for %vars.kv -> $k, $v {
      %vars{$k} [R//]= %*ENV{$k};
    }

    return %vars;
}

#| Takes '$folder/Makefile.in' and writes out '$folder/Makefile'. %vars should
#| be the result of get-vars above.
our sub process-makefile(Str $folder, %vars) is export {
    my $makefile = slurp($folder~'/Makefile.in');
    for %vars.kv -> $k, $v {
        $makefile ~~ s:g/\%$k\%/$v/;
    }
    spurt($folder~'/Makefile', $makefile);
}

#| Calls get-vars and process-makefile for you to generate '$folder/Makefile',
#| then runs your system's 'make' to build it.
our sub make(Str $folder, Str $destfolder) is export {
    my %vars = get-vars($destfolder);
    process-makefile($folder, %vars);

    my $goback = $*CWD;
    chdir($folder);
    my $proc = shell(%vars<MAKE>);
    while $proc.exitcode == -1 {
        # busy wait
        # (shell blocks, so this is in theory not needed)
    }
    if $proc.exitcode != 0 {
        die "make exited with signal "~$proc.exitcode;
    }
    chdir($goback);
}
