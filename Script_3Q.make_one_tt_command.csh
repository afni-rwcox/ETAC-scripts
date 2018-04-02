# script to generate a 3dttest++ command using pre-computed
# results from the FCon1000 collection

# do not run this file in a separate shell via 'tcsh'!
# instead, source this file, with the following variable pre-set
#
#   Dlist   = data directories list                      MANDATORY
#   mask    = mask dataset                               MANDATORY
#   prefix  = prefix for output files                    MANDATORY
#   Slist   = ( list of five digit subject IDs )         MANDATORY
#   Anum    = number of subjects for setA                MANDATORY
#   Bnum    = number of subjects for setB                OPTIONAL
#   Olist   = ( other options to 3dttest++ )             OPTIONAL
#   tempdir = temporary directory (for 3dXClustSim)      OPTIONAL
#   tseed   = seed number for generation of random lists OPTIONAL
#
# output is the variable ttcmd, which can be executed
# to run the program as desired
#
# *** you need to have done 'set noglob' before running   ***
# *** this script and before running the command '$ttcmd' ***

# initialize the 3dttest++ command with universal options

set ttcmd = ( 3dttest++ -DAFNI_DONT_LOGFILE=YES -toz -AminusB -mask $mask )
set ttcmd = ( $ttcmd -prefix $prefix.nii.gz )
if( $?tempdir ) set ttcmd = ( $ttcmd -tempdir $tempdir )

# append the Olist options, if present
if( $?Olist )then
  set ttcmd = ( $ttcmd $Olist )
endif

# create a random number seed
if( $?tseed )then
  set qseed = `count -dig 1 -seed $tseed 10000000 99999999 R1`
else
  set qseed = `count -dig 1              10000000 99999999 R1`
endif

set ttcmd = ( $ttcmd -seed `count -dig 1 -seed $qseed 1000000 9999999 R2` )
@ qseed += 6666

# is this 1-sample or 2-sample?

if( $?Bnum == 0 )then
  set Bnum = 0
else
  if( $Bnum < 10 ) set Bnum = 0
endif

# are we re-using old lists?

if( $?Alist == 0 || $?Blist == 0 || $?ADlist == 0 || $?BDlist == 0 )then
  set need_lists = 1
  set Alist  = ( )
  set Blist  = ( )
  set ADlist = ( )
  set BDlist = ( )
  set snum  = $Anum
  if( $Bnum > 9 ) @ snum = $snum + $Bnum
else
  @ snum = $#Alist + $#Blist
  set need_lists = 0
endif

# make lists of subjects and directories to use

if( $need_lists )then
  set clist = ( `count -seed $qseed -dig 1 1 $#Slist S$snum` )
  @ qseed += 6666
  set qlist = ( `count -seed $qseed -dig 1 1 $#Dlist R$snum` )
  @ qseed += 6666
  foreach sss ( `count -dig 1 1 $Anum` )
    set aaa = $clist[$sss]
    set qqq = $qlist[$sss]
    set Alist  = ( $Alist  $Slist[$aaa] )
    set ADlist = ( $ADlist $Dlist[$qqq] )
  end
  if( $Bnum > 9 )then
    @ bot = $Anum + 1
    foreach sss ( `count -dig 1 $bot $snum` )
      set aaa = $clist[$sss]
      set qqq = $qlist[$sss]
      set Blist  = ( $Blist  $Slist[$aaa] )
      set BDlist = ( $BDlist $Dlist[$qqq] )
    end
  endif
endif

# put the setA datasets onto the command line

set ttcmd = ( $ttcmd -setA setA )
foreach sss ( `count -dig 1 1 $Anum` )
  set aaa = $Alist[$sss]
  set qqq = $ADlist[$sss]
  set ttcmd = ( $ttcmd $aaa $qqq/stats.${aaa}_REML+tlrc.HEAD\'\[1\]\' )
end

# put the setB datasets onto the command line

if( $#Blist > 1 )then
  set ttcmd = ( $ttcmd -setB setB )
  foreach sss ( `count -dig 1 1 $Bnum` )
    set aaa = $Blist[$sss]
    set qqq = $BDlist[$sss]
    set ttcmd = ( $ttcmd $aaa $qqq/stats.${aaa}_REML+tlrc.HEAD\'\[1\]\' )
  end
endif

# make some other lists for possible later use

if( $need_lists )then
  set TTlist = ( $Alist  $Blist  )
  set DDlist = ( $ADlist $BDlist )
endif
