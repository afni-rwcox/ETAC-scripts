#!/bin/tcsh

### This script analyzes one subject's timeseries data (block design).
### MUST be run after Script_1B.warper.csh and Script_1A.makestims.csh

# argv[1] = Stim ID             [e.g., Stim1.Case01]
# argv[2] = subject ID to run   [e.g., sub00156]

if( $#argv < 2 )then
  echo "***** ERROR: Need 2 args = stimID subjID" ; exit 1
endif

# set stimID from arg 1
set stimID = $argv[1]

# set subject ID from arg 2
set subj = $argv[2]

# set thread count if we are running SLURM

if( $?SLURM_CPUS_PER_TASK )then
  setenv OMP_NUM_THREADS $SLURM_CPUS_PER_TASK
endif

# set final output directory and temporary directory
set finaldir = ${subj}.results
if( $?SLURM_JOBID )then
  set tempdir = /lscratch/$SLURM_JOBID/$finaldir
  set usetemp = 1
else
  set tempdir = $finaldir
  set usetemp = 0
endif

# don't log AFNI programs in ~/.afni.log
# don't try any version checks
# don't auto-compress output files
setenv AFNI_DONT_LOGFILE  YES
setenv AFNI_VERSION_CHECK NO
setenv AFNI_COMPRESSOR    NONE
setenv AFNI_DONT_USE_PIGZ YES
setenv AFNI_AUTOGZIP      NO
setenv AFNI_NOMMAP        YES

### set the data directories we will use
# topdir = directory above this Scripts directory
set topdir  = `dirname $cwd`
set restdir = $topdir/rest_orig
set anatdir = $topdir/anat_orig
set warpdir = $topdir/anat_warped
set stimdir = $topdir/stimfiles

set start_directory = $cwd

# set the base dataset for MNI-izing
# (not actually needed since this was done in Script_1.warper.csh)

set basedset = $topdir/MNI152_2009_template.nii
if( ! -f $basedset )then
  echo "***** ERROR: template $basedset is not present" ; exit 1
endif

### this script fragment would find the template if I hadn't
### put it into the top directory for ease of access
#set tpath = `@FindAfniDsetPath $basedset`
#if( "$tpath" == '' ) then
#  echo "***** ERROR: Failed to find template $basedset -- exiting :("
#  exit 1
#endif
#set basedset = $tpath/$basedset

# get some info about the stimulus

set stimfile = $stimdir/${stimID}_01.1D
if( ! -f $stimfile )then
  echo "***** ERROR: Can't find stimfile $stimfile"
  exit 1
endif

set stimfname = `basename $stimfile`
set stimcase  = $stimID
# cut the stimulus duration out of the stimulus filename
set stimdur   = `echo $stimcase  | sed -e 's/\.Case..//' -e 's/Stim//'`
set stimresp  = "BLOCK($stimdur,1)"

# create output directory, if needed

set outdir = $topdir/$stimcase
if( ! -d $outdir )then
  echo "+++++ Creating output directory $outdir"
  mkdir -p $outdir
endif

# copy stimfile there

if( ! -f $outdir/$stimfname )then
  echo "+++++ Copying $stimfile to $outdir/$stimfname"
  cp -f $stimfile $outdir/$stimfname
endif

# enter the output directory for this case

cd $outdir
if( ! -d snapshots ) mkdir -p snapshots

# Check if output file is in the current directory already
# (it would have be put here by the 'moveup' script)

if( -f stats.${subj}_REML+tlrc.HEAD )then
  echo "+++++ output file stats.${subj}_REML+tlrc.HEAD exists -- exiting"
  exit 0
endif

# Process this one subject and this one stimulus

set rest_dset = $restdir/rest_${subj}.nii.gz
set anat_dset = $warpdir/anatSS.${subj}.nii.gz

# if we ran it before but it failed for some reason,
# kill the old version of the results directory and try again

if( -d $finaldir )then
  if( ! -f $finaldir/stats.${subj}_REML+tlrc.HEAD )then
    echo "+++++ WARNING: deleting old output for $stimID $subj"
    \rm -rf *${subj}*
  endif
endif

# Run this if the results don't already exist and the data does

if( ! -d $finaldir && -f $anat_dset && -f $rest_dset )then

  echo "-------------------------------"
  echo "Processing $stimID $subj"
  echo "-------------------------------"

# run afni_proc.py to create a single subject processing script

  afni_proc.py -subj_id $subj -out_dir $tempdir                 \
       -script proc.$subj    -scr_overwrite                     \
       -blocks despike tshift align tlrc volreg                 \
                    mask scale regress                          \
       -copy_anat $anat_dset                                    \
          -anat_has_skull no                                    \
       -dsets $rest_dset                                        \
       -tcat_remove_first_trs 0                                 \
       -align_opts_aea -giant_move                              \
           -cost lpc+ZZ                                         \
       -volreg_align_to MIN_OUTLIER                             \
       -volreg_align_e2a                                        \
       -volreg_tlrc_warp                                        \
       -tlrc_base $basedset                                     \
       -volreg_warp_dxyz 2.0                                    \
       -tlrc_NL_warp                                            \
       -tlrc_NL_warped_dsets                                    \
             $warpdir/anatQQ.${subj}.nii.gz                     \
             $warpdir/anatQQ.${subj}.aff12.1D                   \
             $warpdir/anatQQ.${subj}_WARP.nii.gz                \
       -regress_anaticor_fast                                   \
       -regress_anaticor_fwhm 20                                \
       -regress_stim_times $stimfile                            \
       -regress_stim_labels $stimcase                           \
       -regress_basis "$stimresp"                               \
       -regress_censor_motion 0.2                               \
       -regress_censor_outliers 0.04                            \
       -regress_3dD_stop                                        \
       -regress_make_ideal_sum sum_ideal.1D                     \
       -regress_est_blur_errts                                  \
       -regress_reml_exec                                       \
       -regress_run_clustsim no

# Run analysis
  tcsh -xef proc.${subj} |& tee proc.${subj}.output

# If it worked and was in a temporary directory, copy it back
  if( $usetemp && -d $tempdir )then
    echo "Copying data from $tempdir to $finaldir"
    mkdir -p $finaldir
    \cp -pr $tempdir/* $finaldir
  endif

# If it worked, run the volreg snapshots and compress outputs
  if( -d $finaldir )then
    cd $finaldir
    @snapshot_volreg anat_final.${subj}+tlrc.HEAD \
                     pb0?.${subj}.r01.volreg+tlrc.HEAD ${subj}
    if( -f ${subj}.jpg ) \mv -f ${subj}.jpg ../snapshots/
    cd ..
  endif
else
  echo "-------------------------------------------------------------------"
  echo "+++++ WARNING: Skipping $stimID $subj"
  if( -d $finaldir       ) echo "   $finaldir EXISTS"
  if( ! -f $anat_dset    ) echo "   $anat_dset DOES NOT EXIST"
  if( ! -f $rest_dset    ) echo "   $rest_dset DOES NOT EXIST"
  echo "-------------------------------------------------------------------"
endif

time
exit 0
