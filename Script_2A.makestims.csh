#!/bin/tcsh

## This file makes the Stim*.Case*.1D random timing stimulus files

# top level directory = one above this
set topdir = `dirname $cwd`

# directory where stim files go
set stimdir = $topdir/stimfiles
mkdir -p $stimdir
cd $stimdir

# number of random cases for each stim duration
set ncase = 5

# TR in s
set tr = 2

# number of images in time
set nr = 225

# duration of image run
set dur = `ccalc "${tr}*${nr}"`

# remove any pre-existing stuff
\rm Stim*.Case*.1D HRF*.Case*.1D

# make the 10s block stim

set stimdur = 10
set minrest = 12
set numstim = `ccalc -int "int( ${dur}/((${stimdur}+${minrest})*1.333) )"`

foreach ccc ( `count -dig 2 1 $ncase` )
# create the timing file
  make_random_timing.py                                    \
    -num_stim 1 -num_runs 1                                \
    -pre_stim_rest 4 -post_stim_rest 4 -min_rest $minrest  \
    -tr $tr -tr_locked                                     \
    -stim_dur $stimdur -num_reps $numstim -run_time ${dur} \
    -prefix Stim${stimdur}.Case${ccc}
# create the regression model (for plotting)
  3dDeconvolve                                                        \
    -nodata $nr $tr -polort -1                                        \
    -num_stimts 1                                                     \
    -stim_times 1 Stim${stimdur}.Case${ccc}_01.1D "BLOCK($stimdur,1)" \
    -x1D HRF${stimdur}.Case${ccc}_01.1D
end
\rm HRF*XtXinv*.1D
1dplot -xlabel 'TR' -ylabel "BLOCK($stimdur,1)" \
       -png HRF${stimdur}.png HRF${stimdur}.*.1D

# make the 30s block stim

set stimdur = 30
set minrest = 16
set numstim = `ccalc -int "int( ${dur}/((${stimdur}+${minrest})*1.333) )"`

foreach ccc ( `count -dig 2 1 $ncase` )
# create the timing file
  make_random_timing.py                                    \
    -num_stim 1 -num_runs 1                                \
    -pre_stim_rest 4 -post_stim_rest 4 -min_rest $minrest  \
    -tr $tr -tr_locked                                     \
    -stim_dur $stimdur -num_reps $numstim -run_time ${dur} \
    -prefix Stim${stimdur}.Case${ccc}
# create the regression model (for plotting)
  3dDeconvolve                                                        \
    -nodata $nr $tr -polort -1                                        \
    -num_stimts 1                                                     \
    -stim_times 1 Stim${stimdur}.Case${ccc}_01.1D "BLOCK($stimdur,1)" \
    -x1D HRF${stimdur}.Case${ccc}_01.1D
end
\rm HRF*XtXinv*.1D
1dplot -xlabel 'TR' -ylabel "BLOCK($stimdur,1)" \
       -png HRF${stimdur}.png HRF${stimdur}.*.1D

# make the 1s block stim

set stimdur = 1
set minrest = 5
set numstim = `ccalc -int "int( ${dur}/((${stimdur}+${minrest})*1.666) )"`

foreach ccc ( `count -dig 2 1 $ncase` )
# create the timing file
  make_random_timing.py                                    \
    -num_stim 1 -num_runs 1                                \
    -pre_stim_rest 4 -post_stim_rest 4 -min_rest $minrest  \
    -tr $tr -tr_locked                                     \
    -stim_dur $stimdur -num_reps $numstim -run_time ${dur} \
    -prefix Stim${stimdur}.Case${ccc}
# create the regression model (for plotting)
  3dDeconvolve                                                        \
    -nodata $nr $tr -polort -1                                        \
    -num_stimts 1                                                     \
    -stim_times 1 Stim${stimdur}.Case${ccc}_01.1D "BLOCK($stimdur,1)" \
    -x1D HRF${stimdur}.Case${ccc}_01.1D
end
\rm HRF*XtXinv*.1D
1dplot -xlabel 'TR' -ylabel "BLOCK($stimdur,1)" \
       -png HRF${stimdur}.png HRF${stimdur}.*.1D

# we is done

exit 0
