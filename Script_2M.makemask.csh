#!/bin/tcsh

## Run this to create a mask for group analysis.
## It creates a resampled GM+CSF mask from the
## MNI template, and then the intersection of
## that with the single-subject masks.

# where the data lives
set topdir = `dirname $cwd`
set odir   = Stim10.Case01
set scd    = $cwd

cd $topdir

# list of single subject masks
set mlist = ( `find $odir -name full_mask.\*+tlrc.HEAD` )

echo "Found $#mlist masks"
if( $#mlist == 0 ) exit 1

# find the MNI template dataset (if needed)

set Basedset = MNI152_2009_template.nii

if( -f $Basedset )then
  echo "Found $Basedset"
else if( -f $Basedset.gz )
  gzip -d $Basedset.gz
  echo "Uncompressed $Basedset"
else
  set tpath = `@FindAfniDsetPath $Basedset.gz`
  if( "$tpath" == '' ) then
    echo "***** Failed to find template $Basedset.gz -- exiting :(" ; exit 1
  endif
  echo "Copying $Basedset to $cwd"
  cp -f $tpath/$Basedset.gz .
  gzip -d $Basedset.gz
endif

# resample the MNI mask to the same grid

if( -f temp.mask.nii ) \rm -f temp.mask.nii

3dresample -master $mlist[1] -rmode NN  \
           -input ${Basedset}'[GCmask]' \
           -prefix temp.mask.nii

# make an intersection of all the above masks

if( -f mask_interGC.nii ) \rm -f mask_interGC.nii

3dmask_tool -input temp.mask.nii $mlist        \
            -prefix mask_interGC.nii -frac 1.0

\rm -f temp.mask.nii

time ; exit 0
