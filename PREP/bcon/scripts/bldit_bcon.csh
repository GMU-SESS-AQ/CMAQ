#! /bin/csh -f

# ====================== BCONv5.2 Build Script ====================== #
# Usage: bldit.bcon >&! bldit.bcon.log                                #
# Requirements: I/O API & netCDF libs, Git, and a Fortran compiler    #
# Note that this script is configured/tested for Red Hat Linux O/S    #
# The following environment variables must be set for this script to  #
# build an executable.                                                #
#   setenv MODEL < Git repository source code >                       #
#   setenv M3LIB   <code libraries>                                   #
# To report problems or request help with this script/program:        #
#             http://www.cmascenter.org/html/help.html                #
# =================================================================== #

 set BLD_OS = `uname -s`        ## Script set up for Linux only 
 if ($BLD_OS != 'Linux') then
    echo "   $BLD_OS -> wrong bldit script for host!"
    exit 1
 endif

#> Source the config.cmaq file to set the build environment
 source ../../../../config.cmaq

#> Check for M3HOME and M3LIB settings:
 if ( ! -e $M3HOME || ! -e $M3LIB ) then 
    echo "   $M3HOME or $M3LIB directory not found"
    exit 1
 endif
 echo "   Model repository path: $M3HOME"
 echo "            library path: $M3LIB"

#> If $REPO not set, default to $M3HOME
 if ( $?REPO ) then
    echo "         Model repository path: $REPO"
 else
    setenv REPO $M3HOME
    echo " default Model repository path: $REPO"
 endif

 set echo

#> Source Code Repository
 setenv REPOROOT $REPO/PREP/bc/BCON/src  #> location of the source code for BLDMAKE
 set MODEL = $REPOROOT             #> location of the BCON source code
 set Mechs = $REPO/CCTM/src/MECHS  #> location of the chemistry mechanism defining files

#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#><#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#
#>#>#>#>#>#>#>#>#>#>#>#>#># Begin User Input Section #<#<#<#<#<#<#<#<#<#<#<#<#<#

#> user choices: base working directory and application ID
 set Base = $cwd                    #> working directory
 set APPL = v52_profile             #> model configuration ID
#set APPL = v52_m3conc              #> model configuration ID
 set EXEC = BCON_${APPL}_$EXEC_ID   #> executable name for this application
 set CFG  = cfg.$EXEC               #> BLDMAKE configuration file name

#> user choice: copy source files
 set CopySrc        # copy the source files into the BLD directory

#set Opt = verbose  # show requested commands as they are executed

#> user choice: make a Makefile
 set MakeFileOnly   # builds a Makefile to make the model, but does not compile -
                    # comment out to also compile the model (default if not set)

#>==============================================================================
#> BCON Science Modules selection
#> NOTE: For the modules with multiple choices, choose by uncommenting.
#> look in the BCON source code repository or refer to the CMAQ documentation
#> for other possible options. Be careful. Not all options work together.
#>==============================================================================

 set ModCommon = common

 set ModType   = profile
#set ModType   = m3conc
#set ModType   = tracer

#> user choices: mechanism  (see CCTM/src/MECHS for list)
#set Mechanism = cb05tucl_ae6_aq/
#set Mechanism = cb05tump_ae6_aq/
 set Mechanism = cb05e51_ae6_aq/
#set Mechanism = cb05mp51_ae6_aq/
#set Mechanism = saprc07tb_ae6_aq/
#set Mechanism = saprc07tc_ae6_aq/
#set Mechanism = saprc07tic_ae6i_aq/
#set Mechanism = racm2_ae6_aq/
 set Tracer    = trac0               # default: no tracer species

#>#>#>#>#>#>#>#>#>#>#>#>#>#> End User Input Section #<#<#<#<#<#<#<#<#<#<#<#<#<#
#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#

#> Set full path of Fortran 90 compiler
 set FC = ${myFC}
 set FP = $FC

#> Set IO/API version
 set IOAPI = ioapi_3.1

#> Set compiler flags
 set xLib_Base  = ${M3LIB}
 set xLib_1     = $IOAPI/Linux2_${system}${compiler_ext}
 set xLib_2     = $IOAPI/ioapi/fixed_src
 set FSTD       = "${myFSTD}"
 set DBG        = "${myDBG}"
 set F_FLAGS    = "${myFFLAGS}"
 set F90_FLAGS  = "${myFRFLAGS}"
 set CPP_FLAGS  = ""
 set LINK_FLAGS = "${myLINK_FLAG}"

 set LIB1 = "-lioapi"
 set LIB2 = "-lnetcdff -lnetcdf"

#> invoke BLDMAKE for serial execution
 set Blder = "$REPO/UTIL/bldmake/src/BLDMAKE -serial -verbose"

#> The "BLD" directory for compiling source code (and possibly copying the code to)
 set Bld = $Base/BLD_BCON_${APPL}
 if ( ! -e "$Bld" ) then
    mkdir $Bld
 else
    if ( ! -d "$Bld" ) then
       echo "   *** target exists, but not a directory ***"
       exit 1
    endif
 endif

 cd $Bld

#source $Base/relinc.bcon
#if ( $status ) exit 1

#set ICL_MECH  = $Mechs/$Mechanism
#set ICL_TRAC  = $Mechs/$Tracer

#if ( $?CopySrc ) then
#   /bin/cp -fp ${ICL_MECH}/*    ${Bld}
#   /bin/cp -fp ${ICL_TRAC}/*    ${Bld}
#endif

 if ( $?CopySrc ) then
    /bin/cp -fp $Mechs/$Mechanism/*.nml $Bld
    /bin/cp -fp $Mechs/$Tracer/*.nml $Bld
 else
    /bin/ln -s $Mechs/$Mechanism/*.nml $Bld
    /bin/ln -s $Mechs/$Tracer/*.nml $Bld
 endif

#> make the config file

 set Cfile = $CFG
 set quote = '"'

 echo                                                               > $Cfile
 echo "model       $EXEC;"                                         >> $Cfile
 echo                                                              >> $Cfile
 echo "repo        $MODEL;"                                        >> $Cfile
 echo                                                              >> $Cfile
 echo "mechanism   $Mechanism;"                                    >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_base    $xLib_Base;"                                    >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_1       $xLib_1;"                                       >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_2       $xLib_2;"                                       >> $Cfile
 echo                                                              >> $Cfile
 set text = "$quote$CPP_FLAGS$quote;"
 echo "cpp_flags   $text"                                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f_compiler  $FC;"                                           >> $Cfile
 echo                                                              >> $Cfile
 echo "fstd        $quote$FSTD$quote;"                             >> $Cfile
 echo                                                              >> $Cfile
 echo "dbg         $quote$DBG$quote;"                              >> $Cfile
 echo                                                              >> $Cfile
 echo "f_flags     $quote$F_FLAGS$quote;"                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f90_flags   $quote$F90_FLAGS$quote;"                        >> $Cfile
 echo                                                              >> $Cfile
 echo "link_flags  $quote$LINK_FLAGS$quote;"                       >> $Cfile
 echo                                                              >> $Cfile
#echo "libraries   $quote$LIBS$quote;"                             >> $Cfile
 echo "ioapi       $quote$LIB1$quote;"                             >> $Cfile
 echo                                                              >> $Cfile
 echo "netcdf      $quote$LIB2$quote;"                             >> $Cfile
 echo                                                              >> $Cfile

 set text="// mechanism:"
 echo "$text ${Mechanism}"                                         >> $Cfile
 echo "// project repository location: ${MODEL}"                   >> $Cfile
 echo                                                              >> $Cfile
#if ( $compiler == gfort ) then
#  set ICL_MECH = '.'
#endif
#echo "include SUBST_RXCMMN     $ICL_MECH/RXCM.EXT;"               >> $Cfile
#echo "include SUBST_RXDATA     $ICL_MECH/RXDT.EXT;"               >> $Cfile
 echo                                                              >> $Cfile

 set text = "common"
 echo "// required" $text                                          >> $Cfile
 echo "Module ${ModCommon};"                                       >> $Cfile
 echo                                                              >> $Cfile

 set text = "profile, m3conc, tracer"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModType};"                                         >> $Cfile
 echo                                                              >> $Cfile

 if ( $?ModMisc ) then
    echo "Module ${ModMisc};"                                      >> $Cfile
    echo                                                           >> $Cfile
 endif

#> make the makefile or the model executable

 unalias mv rm
 if ( $?MakeFileOnly ) then
    if ( $?CopySrc ) then
       $Blder -makefo $Cfile
    else
       $Blder -makefo -git_local $Cfile   # $Cfile = ${CFG}
     # totalview -a $Blder -makefo $Cfile
    endif
 else   # also compile the model
    if ( $?CopySrc ) then
       $Blder $Cfile
    else
       $Blder -git_local $Cfile
    endif
 endif
 mv Makefile $Bld/Makefile.$compiler
 if ( -e Makefile.$compiler && -e Makefile ) rm Makefile
 ln -s Makefile.$compiler Makefile

 if ( $status != 0 ) then
    echo "   *** failure in $Blder ***"
    exit 1
 endif
 if ( -e "$Base/${CFG}" ) then
    echo "   >>> previous ${CFG} exists, re-naming to ${CFG}.old <<<"
    mv $Base/${CFG} $Base/${CFG}.old
 endif

 cd $MODEL
 set brnch = `git branch`
 unset echo
 @ i = 0
 while ( $i < $#brnch )
    @ i++
    if ( "$brnch[$i]" == "*" ) @ l = $i + 1
 end
 set rep = `echo $cwd | tr "/" "#"`
 set rln = "repo:${rep},branch:${brnch[$l]},compiler:${compiler}"
 set ref = $Bld/$rln
 /bin/touch $ref
 if ( -d $MODEL/branch ) /bin/cp $MODEL/branch/branch.* $Bld

 exit