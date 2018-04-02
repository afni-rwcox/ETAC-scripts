#!/bin/tcsh

### Script to move up the regression results from the individual
###  subject output directories to their parent directory, then
###  delete the corresponding output directory.
### This is to be run when all regression analyses are
###  completed successfully, to save disk space and make
###  accessing the beta files simpler for group analyses.

set site = Beijing
set Sublist = ( `cat $site.list.txt` )
set Stimlist = ( Stim1.Case01  Stim10.Case01  Stim30.Case01 \
                 Stim1.Case02  Stim10.Case02  Stim30.Case02 \
                 Stim1.Case03  Stim10.Case03  Stim30.Case03 \
                 Stim1.Case04  Stim10.Case04  Stim30.Case04 \
                 Stim1.Case05  Stim10.Case05  Stim30.Case05  )

# top level directory is the one above this Scripts directory
set topdir = `dirname $cwd`
cd topdir

foreach stimdir ( $Stimlist )

  cd $stimdir

  foreach sub ( $Sublist )

# subject output directory
    set sdir = ${sub}.results
# desired file with betas
    set hfil = stats.${sub}_REML+tlrc.HEAD

# already there == skip
    if(   -f $hfil )       continue
# no output directory == skip
    if( ! -d $sdir )       continue
# no output file == skip
    if( ! -f $sdir/$hfil ) continue

# list of desirable output files (.HEAD and .BRIK)
    set sss = ( $sdir/stats.${sub}_REML+tlrc.* )

# if list is too short, skip
    if( $#sss < 2 ) continue

# do the copying
    \cp -fp $sss .

# check if copying worked OK
    foreach fff ( $sss )
      set bbb = `basename $sss`
      set nre = 0
      set qq = ( `ls -l $fff` ) ; set fs = $qq[5]
 RLOOP:
      set retry = 0
      if( ! -f ./$bbb )then
        echo "ERROR: cp $fff . failed completely -- retrying"
        set retry = 1
      else
# get file sizes
        set qq = ( `ls -l $bbb` ) ; set bs = $qq[5]
        if( "$bs" != "$fs" )then
          echo "ERROR: cp $fff . was incomplete; filesize $bs < $fs -- retrying"
          set retry = 1
        endif
      endif
      if( $retry != 0 )then
        sync ; sleep 1 ; \cp -fpv $fff .
        @ nre ++
        if( $nre < 9 ) goto RLOOP
      endif
    end

  end

  cd ..

end

# number of results needed
@ num_needed = $#Sublist * $#Stimlist

exit 0
