# this script submits a job to the lxplus batch queue to go through each sample of a particular release
# and create a .txt file with the cutflow information.  As the job runs, these files
# are created and copied to cutflows/HTAG/FULLSAMPLENAME.txt
# usage: source batchSubmitter.sh h011


[[ -z "$1" ]] && echo "NEED 1st arugment!" && return

[[ -z "$datasetDir" ]] && echo "please source the setup script" && return
[[ ! -d $BASEDIR/AllCutflows/outputbatch ]] && mkdir $BASEDIR/AllCutflows/outputbatch
htagNew=$1
[[ ! -d $BASEDIR/AllCutflows/cutflows/$htagNew ]] && mkdir -p $BASEDIR/AllCutflows/cutflows/$htagNew

sed -i "s|^export BASEDIR=.*|export BASEDIR=${BASEDIR}|g" $BASEDIR/AllCutflows/getCutflowBatch.sh


echo ${VARSFORCUTFLOWS[@]} | sed 's/ /, /g' | sed 's/^/enum CutEnum {/g' | sed 's/$/};/g' > $BASEDIR/AllCutflows/cutflow_vars.h
echo '// This file is automatically generated by getCutflows.sh.  To change the cutflows variables, change the setup script' >> $BASEDIR/AllCutflows/cutflow_vars.h

rm -r $BASEDIR/AllCutflows/outputbatch/*

SampleDirs=()
SampleDirs+=($(eos ls $datasetDir/$htagNew/ | grep -v "root"))

Samples=()
for DIR in ${SampleDirs[@]}; do
  Samples+=($(eos ls $datasetDir/$htagNew/$DIR/ | grep .root ))
  [[ $DIR =~ data ]] && Samples+=($(eos ls $datasetDir/$htagNew/$DIR/runs/ | grep .root))
done
resetProgressBar



echo Submitting batch job for cutflows... This job takes 30mins-1h to finish, cutflows are updated as the job runs
echo SUBMITOUT > $BASEDIR/AllCutflows/submit.out
for fileName in ${Samples[@]}; do
  bsub -R "swp > 20000" -R "rusage[mem=500]" -q 8nh $BASEDIR/AllCutflows/getCutflowBatch.sh $fileName $htagNew  >> $BASEDIR/AllCutflows/submit.out
  tickProgressBar ${#Samples[@]}
done
endProgressBar
