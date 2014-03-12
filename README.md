daisychain
==========

Scripts for repeatedly restarting jobs until completion on HPC clusters

The SLURM script template is finished.  I could have broken things out to multiple files to be more concise, but I left everything in one file for the sake of simplicity.  When submitting a dependent job, some clusters may require that you ssh back into a login node to submit a dependent job, which is accounted for in this script.  If that is not required for your cluster, you can simply edit that line in the script.  Be sure your system administrators are okay with automatically requeuing jobs like this before you use daisychain.

