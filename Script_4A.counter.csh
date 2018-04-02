#!/bin/tcsh

### Script to count positive events in a list
###   of directories provided in the arguments.
### Results table is printed to stdout. 

cd ..

set dlist = ( $argv )
if( $#dlist == 0 )then
  echo "ERROR: no arguments" ; exit 1
endif

# ETAC mask output filenames are like so
#   ${pref}.${kkk}.${nam}s${ss}h${hh}.ETACmask.$tt.${perc}perc.nii.gz
# where
#   pref = extracted from directory name
#   kkk  = digits (e.g., '0000')
#   nam  = given below
#   ss   = sidedness of t-test ('1' or '2')
#   hh   = hpow list (given below)
#   tt   = type of t-test ('1pos', '1neg', or '2sid')
#   perc = FPR percent ('2' .. '9')

set nam  = P010-001
set hnam = 2

# list of FPR percents
set plist = ( 2 3 4 5 6 7 8 9 )

# range of number to scan for 'kkk'
set kbot = 0
set ktop = 999

## scan over input directories

foreach fred ( $dlist )

  if( ! -d $fred )then
    echo "ERROR -- can't find directory $fred" ; continue
  endif

  pushd $fred

# extract the filename prefix from the directory name
# (remove the 'StimXX.' at the beginning)
  set pref = `echo $fred | sed -e 's/St.*\.//'`
  echo "pref = $pref"

# loop over sub-cases, and initialize output counts
#   stot = total number of runs found
#   snum = total number of FPRs found
  foreach ss ( 1 2 )
  foreach tt ( 1neg 1pos 2sid )
  foreach hh ( $hnam )
  foreach perc ( $plist )
    set stot_s${ss}h${hh}_${tt}_${perc} = 0
    set snum_s${ss}h${hh}_${tt}_${perc} = 0
  end
  end
  end
  end

# loop over numbered runs
  foreach kkk ( `count -dig 4 $kbot $ktop` )

# a short pause to refresh ourselves
    set rr = `ccalc -int "mod($kkk,99)"` ; if( $rr == 27 ) sleep 1

# loop over sub-cases
    foreach ss ( 1 2 )
    foreach tt ( 1neg 1pos 2sid )
    foreach hh ( $hnam )
    foreach perc ( $plist )
# assemble ETAC output filename
      set emask = ${pref}.${kkk}.${nam}s${ss}h${hh}.ETACmask.$tt.${perc}perc.nii.gz

# count it as existing (stot) and see if it has any nonzero values (snum)
      if( -f $emask )then
        set nnn = `3dBrickStat -non-zero -count $emask`
        @ stot_s${ss}h${hh}_${tt}_${perc} ++
        if( $nnn > 0 ) @ snum_s${ss}h${hh}_${tt}_${perc} ++
      endif

    end
    end
    end
    end

# end of loop over numbered runs
  end

## loop to format output counts (all 'perc' values in one row)

  foreach hh ( $hnam )
  foreach ss ( 1 2 )
  foreach tt ( 1neg 1pos 2sid )
    set sntot = ( )
    set snnum = ( )
    set sperc = ( )
    set spbot = ( )
    set sptop = ( )
    foreach perc ( $plist )
# get the number of runs and the number of positives
      set tmp = \$"stot_s${ss}h${hh}_${tt}_${perc}" ; set ntot = `eval echo $tmp`
      set tmp = \$"snum_s${ss}h${hh}_${tt}_${perc}" ; set nnum = `eval echo $tmp`
      if( $ntot > 0 )then
# build the tables of outputs for this sub-case
        set sntot = ( $sntot $ntot )
        set snnum = ( $snnum $nnum )
# FPR percent
        set sperc = ( $sperc `ccalc -form '%4.2f' "100*$nnum/$ntot"` )
# binomal 95% CI
        set spbot = ( $spbot `ccalc -form '%4.2f' "100*cdf2stat(0.025,7,$nnum+0.5,$ntot-$nnum+0.5,0)"` )
        set sptop = ( $sptop `ccalc -form '%4.2f' "100*cdf2stat(0.975,7,$nnum+0.5,$ntot-$nnum+0.5,0)"` )
      else
        set sntot = ( $sperc 0 )
        set snnum = ( $sperc 0 )
        set sperc = ( $sperc 0 )
        set spbot = ( $spbot 0 )
        set sptop = ( $sptop 0 )
      endif
    end
# output formatted results for 2% .. 9% nominal FPR tests
    if( "$sntot[8]" != "0" )then
      echo "=== t-test: $tt  h=$hh"
# total runs completed
      printf " %6d %6d %6d %6d %6d %6d %6d %6d\n" \
             $sntot[1] $sntot[2] $sntot[3] $sntot[4] $sntot[5] $sntot[6] $sntot[7] $sntot[8]
# total positives
      printf " %6d %6d %6d %6d %6d %6d %6d %6d\n" \
             $snnum[1] $snnum[2] $snnum[3] $snnum[4] $snnum[5] $snnum[6] $snnum[7] $snnum[8]
# converted to percent FPR
      printf " %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %% $fred\n" \
             $sperc[1] $sperc[2] $sperc[3] $sperc[4] $sperc[5] $sperc[6] $sperc[7] $sperc[8]
# lower bound of CI
      printf " %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n" \
             $spbot[1] $spbot[2] $spbot[3] $spbot[4] $spbot[5] $spbot[6] $spbot[7] $spbot[8]
# upper bound of CI
      printf " %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n" \
             $sptop[1] $sptop[2] $sptop[3] $sptop[4] $sptop[5] $sptop[6] $sptop[7] $sptop[8]
    endif
  end
  end
  end

  popd

# end of loop over directories
end

exit 0
