module LibraryMake;

our sub get-vars($destfolder) is export {
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

    return %vars;
}

our sub process-makefile($folder, %vars) is export {
    my $makefile = slurp($folder~'/Makefile.in');
    for %vars.kv -> $k, $v {
        $makefile ~~ s:g/\%$k\%/$v/;
    }
    spurt($folder~'/Makefile', $makefile);
}

our sub make($folder, $destfolder) is export {
    my %vars = get-vars($destfolder);
    process-makefile($folder, %vars);

    my $goback = $*CWD;
    chdir($folder);
    shell(%vars<MAKE>);
    chdir($goback);
}
