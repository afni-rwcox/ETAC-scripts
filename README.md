
----------------- Scripts for ETAC Testing -------------------

-----------------    RW Cox -- Mar 2018    -------------------

Beijing.list.txt = This file has the list of the identifiers
                   for the 198 subjects in the collection.
                   It is used in some of the scripts below
                   to generate job lists.

All scripts below are written in the shell language 'tcsh',
and can be executed by (e.g.) 'tcsh Script_1B.warper.submit'.
These scripts are meant to be started from within this Scripts
directory, and will 'cd' to the appropriate directory as needed.

This collection of scripts CANNOT be run on a single computer.
They would take several years to complete. You need to have
access to a cluster of Linux/Unix systems to carry out all
these analyses.

The '.submit' scripts below run collections of jobs on a SLURM
system (https://slurm.schedmd.com/) -- a Linux cluster managed
by the SLURM software. This is the type of system that the NIH
uses, and undoubtedly any non-NIH user of these scripts will
have to alter the way jobs are sent for execution.

The Beijing datasets are organized into two directories, one
level above this 'Scripts' directory (the 'top level'):

  anat_orig = 198 structural datasets (anats)

  rest_orig = 198 resting FMRI datasets

Other directories will be created during the processing, as
described en passant, infra.

----- STEP 1: Warping subject anats to MNI template -----

This is a preliminary operation, so that all subjects will be
in the same 'space' for group analyses.

Script_1A.get.template   = This script must be run first, to
                           copy the MNI template dataset from
                           its home in the AFNI binaries
                           directory to the top level directory.
                           It only need to be run once.

Script_1B.warper.csh     = This script does the warping for
                           one subject, invoking AFNI's @SSwarper
                           script. On the NIH cluster,
                           each job takes 1.5-2 hours.

Script_1B.warper.alljobs = This script is the list of 198
                           invocations of the single subject
                           warping script above.

Script_1B.warper.submit  = This script submits the 198 jobs
                           above to the SLURM system for
                           execution.

Results are stored in a new top level directory named anat_warped.
All 198 jobs must be run successfully before proceeding to STEP 2.
This command will tell you if anat_warped is complete:

  ls ../anat_warped/*_WARP.nii.gz | wc -l

The output of this command (to stdout) should be 198. If it is
less than 198, the missing results will have to be created by
running the appropriate jobs again.

The quality of the alignments can be judged by looking at the
JPEG images in anat_warped/snapshots. Anything that is grossly
wrong should be fixed. In the present case, none of the initial
alignments had any serious flaws -- the @SSwarper script usually
works pretty well, but it is important to make sure.

----- STEP 2: Individual subject time series analyses -----

This second preliminary step is to provide the 'raw material' for
the group analyses of STEP 3.

The outputs from this step will go into 15 top level directories
(i.e., in the directory above this Scripts directory), with names
of the form StimD.CaseNN where 'D' is the stimulus duration
(1, 10, or 30), and 'NN' is the randomized timing case number
(01, 02, 03, 04, or 05); for example, Stim10.Case03.

Script_2A.makestims.csh        = This script must be run first (just
                                 one time), to create the stimulus
                                 timing files (into a top level
                                 directory named stimfiles).

Script_2B.regress.csh          = This script runs the analysis for
                                 one subject, for one stimulus
                                 timing file. On the NIH cluster,
                                 each job takes about an hour.

Script_2B.regress.alljobs.make = This script makes the file
                                 Script_2B.regress.alljobs, which
                                 is the list of commands to run
                                 Script_2B.regress.csh over all
                                 198 subjects and all 15 stimulus
                                 timing files (2970 jobs).

Script_2B.regress.submit       = This script submits the job list
                                 in Script_2B.regress.alljobs.

Script_2M.makemask.csh         = This script should be run once,
                                 after the Stim10.Case01 results
                                 are finished (but before running
                                 Script_2X.moveup.csh). It will
                                 make an intersection mask from all
                                 the EPI datasets and the MNI template
                                 GM+CSF mask, for use in STEP 3.

Script_2X.moveup.csh           = This script moves the statistics
                                 outputs from the analyses up to
                                 the higher level StimD.NN directory.

After running Script_2A.makestims.csh (once), then start by running
Script_2B.regress.alljobs.make. Then submit the jobs: at the NIH, by
running Script_2B.regress.submit. When those jobs are all finished,
run Script_2X.moveup.csh. All 2970 results are needed to be finished
and moved before STEP 3 can be started.

The command

  ls ../Stim*/stats.sub*_REML+tlrc.HEAD | wc -l

will tell you how many results are successfully computed and moved
up into the StimD.NN directories. If this number is less than 2970,
you will have to re-run Script_2B.regress.alljobs.make -- this script
will NOT include commands to make files that are already present.
Then re-submit Script_2B.regress.submit, wait until all jobs are done,
and re-run Script_2X.moveup.csh. Count the outputs again, and continue
until all 2970 are present. The scripts are written this way since it
often happens that several jobs fail for random opaque reasons.

The processing script Script_2B.regress.csh uses a temporary directory
to create the output, then copies that directory back to the final
output location. The reason for this roundabout dance is to let the
results be computed on a local SSD drive, which will be faster than
using a networked storage system. If your cluster does not have this
capability (local drives on each node), then you'll have to omit the
lines where tempdir is set to /lscratch/$SLURM_JOBID/$finaldir and
usetemp is set to 1, so that the results will be computed directly
into the final directory.

----- STEP 3: Running 3dttest++ a lot to build statistics -----

Finally! You get to run t-test simulations, drawing from the pool
of 198 subjects, 3 stimulus timing setups, 5 cases each, to find
"activation" results -- which (when present) are false positives.

Script_3B.ttest.2sam.csh           = Script to run one ETAC job

Script_3B.ttest.2sam.Stim10.submit = Script to submit 1000 ETAC jobs for
                                     the Stim10 case; you can copy and
                                     edit it for the other Stim cases.

Script_3Q.make_one_tt_command.csh  = Sub-script of Script_3B.ttest.2sam.csh
                                     to assemble the 3dttest++ command with
                                     a random collection of input datasets.

Running Script_3B.ttest.2sam.Stim10.submit will create a file
Script_3B.ttest.2sam.Stim10.alljobs with the list of jobs to run,
and then submit them. A job that is already completed will not be
re-started. The reason for writing the script this way is that sometimes
jobs fail, due to problems with the networked filesystem, with a CPU node,
or other weird things. If after trying to run 1000 jobs, only 800 finish
the first time (say), you can just re-run Script_3B.ttest.2sam.Stim10.submit
to re-start the 200 that failed. Of course, you should examine the stderr
outputs from the failed jobs to figure out what the problems were.

----- STEP 4: Counting up the results -----

After all that work, you finally get some numbers. It's amazing how much
effort and time it takes to get the small tabular outputs.

Script_4A.counter.csh = Counts the results in an output directory,
                        and prints (to stdout) a table with observed
                        FPRs for nominal FPR cases 2%..9%. This script
                        does NOT assume all 1000 jobs are completed
                        when computing the statistics, so it can be
                        used on an incomplete output directory. If
                        only 947 (say) ETAC runs complete in STEP 3,
                        you might well consider those results to be
                        "good enough".

For example,

  tcsh Script_4A.counter.csh Stim10.TT2samA

will give the statistics from the results of the jobs submitted by

  tcsh Script_3B.ttest.2sam.Stim10.submit

There are no scripts here to plot these tabular results.
