#!/bin/bash
#
#------------------Scheduler Options--------------------
#SBATCH -J daisychain          # Job name
#SBATCH -N 1                   # Total number of nodes (16 cores/node)
#SBATCH -n 16                  # Total number of tasks
#SBATCH -p normal              # Queue name
#SBATCH -o output.%j           # Name of stdout output file (%j expands to jobid)
#SBATCH -t 48:00:00            # Run time (hh:mm:ss)
# <--- (Use the next line ONLY if you have MULTIPLE accounts) --->
#SBATCH -A 
#------------------------------------------------------

# To daisy chain jobs, the script must know the name of the job submission script.
# 1) if the $myJobScript environment variable is set, that will be used
# 2) by default, the script is set to look in the working directory for a *.slurm file
# The use case is that daisychain jobs will all have their own directory and also 
# their own unique job name.

#----------------------User Options------------------------
myJobScript=$(ls -t $SLURM_SUBMIT_DIR/*.slurm | tail -n 1 )
loginNode="login1"
#----------------------------------------------------------

# check if we should already be finished
baseSlurmJobName=$(echo ${SLURM_JOB_NAME} | sed 's/[0-9]*$//g')
if [ -f ~/.daisychain/finished ]; then
  jobDir=${baseSlurmJobName}$(date +%y-%m-%d_%H%M%S)
  mkdir -p ~/.daisychain/history/${jobDir}
  mv ~/.daisychain/* ~/.daisychain/history/${jobDir}
  # and we're done.  We cleaned out the progress files, time to quit
  echo "Found a "finished" file in ~/.daisychain.  Job series is complete, and progress files have been moved to ~/.daisychain/history/${jobDir}"
  exit
fi

# use the filesystem to keep track of our long job
if [ ! -d ~/.daisychain ]; then # we must be the first job
  mkdir ~/.daisychain
  mkdir ~/.daisychain/history
  thisJobNumber=1
else
  lastJobNumber=$(ls ~/.daisychain | egrep "^[0-9]+$" | sort -n | tail -n 1)
  if [ -z $lastJobNumber ]; then
    thisJobNumber=1
  else
    thisJobNumber=$(( lastJobNumber + 1 ))
  fi
fi

# log
touch ~/.daisychain/$thisJobNumber
echo "Slurm Job number $SLURM_JOB_ID entitled ${SLURM_JOB_NAME} started on $(date) on node(s) $SLURM_NODELIST." > ~/.daisychain/$thisJobNumber

# submit dependent job
nextJobNumber=$(( thisJobNumber + 1 ))
nextSlurmJobName=${baseSlurmJobName}$nextJobNumber

echo "Submitting Dependent Job:"
ssh $loginNode "cd $PWD; env sbatch -J $nextSlurmJobName --dependency=afterany:$SLURM_JOB_ID ${myJobScript}"



#-------------------Job Goes Here--------------------------
# Job goes here. This could be done multiple ways.  Assuming we need continued
# jobs to be different from the first job, I would frame it out this way:
if [ "$thisJobNumber" -eq "1" ]; then
 #first job
 echo "Starting First Job:"
 g09 < first_input > output_$thisJobNumber
else
 #continuation
 echo "Starting Continuation Job:"
 g09 < continued_input > output_$thisJobNumber
fi
#----------------------------------------------------------



# if this runs, the job completed:
touch ~/.daisychain/finished

# it would be fairly safe to do cleanup here and delete pending jobs, but for my purposes it is okay to let the next job do it at startup.
