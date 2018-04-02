#!/bin/tcsh

### This script nonlinear warps one anatomical dataset,
### taken from the anat_orig directory, to the MNI 2009
### nonlinear template (supplied with AFNI binaries), and
### pute the resulting files into the anat_warped directory.

### The only command line argument is the subject ID
set sub  = $argv[1]
set site = Beijing

# set thread count if we are running SLURM
if( $?SLURM_CPUS_PER_TASK )then
  setenv OMP_NUM_THREADS $SLURM_CPUS_PER_TASK
endif

# don't log AFNI programs in ~/.afni.log
# don't try any version checks
# don't auto-compress output files
setenv AFNI_DONT_LOGFILE  YES
setenv AFNI_VERSION_CHECK NO
setenv AFNI_COMPRESSOR    NONE

### go to anat data directory
# topdir = directory above this Scripts directory
set topdir  = `dirname $cwd`
cd $topdir/anat_orig

### create final output directories
mkdir -p $topdir/anat_warped
mkdir -p $topdir/anat_warped/snapshots

### create temporary directory to hold the work
### for this subject , and copy the anat there
mkdir -p temp_$sub
cp anat_$sub.nii.gz temp_$sub
cd temp_$sub

### process the anat dataset, using the AFNI script
### that does the warping and skull-stripping

@SSwarper anat_$sub.nii.gz $sub

# compress the output datasets

gzip -1v *.nii

### move the results to where they belong

# skull-stripped original, Q-warped dataset, and the warps

\mv -f anatSS.${sub}.nii.gz   anatQQ.${sub}.nii.gz      \
       anatQQ.${sub}.aff12.1D anatQQ.${sub}_WARP.nii.gz \
       $topdir/anat_warped

# move snapshots for visual inspection of alignments

\mv -f *.jpg $topdir/anat_warped/snapshots

# delete the temporary directory
cd ..
\rm -rf temp_$sub

time
exit 0
