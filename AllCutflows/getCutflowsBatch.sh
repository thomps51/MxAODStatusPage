
[[ -z "$1" ]] && echo "NEED 1st arugment! newHtag e.g. h011" && exit 1
[[ -z "$2" ]] && echo "NEED 2nd arugment! oldHtag e.g. h010" && exit 1
# This base dir is automatically set by batchSubmitter, changing it will do nothing since it will be reset
export BASEDIR=/afs/cern.ch/user/a/athompso/www/

source /afs/cern.ch/project/eos/installation/atlas/etc/setup.sh
source $BASEDIR/setup.sh -noAthena

echo started $0 at $(date)
htagNew=$1
htagOld=$2

[[ -z "$datasetDir" ]] && echo Please source the setup script!! && exit
[[ ! -d cutflows ]] && mkdir cutflows
#echo ${VARSFORCUTFLOWS[@]} | sed 's/ /, /g' | sed 's/^/enum CutEnum {/g' | sed 's/$/};/g' > cutflow_vars.h
#echo '// This file is automatically generated by getCutflows.sh.  To change the cutflows variables, change the setup script' >> cutflow_vars.h

for htag in $htagNew $htagOld; do
  #break 
  Samples=()
  for DIR in ${MXAODDIRS[@]}; do
    Samples+=($(eos ls $datasetDir/$htag/$DIR/ ))
    #break
  done
  
  echo "Making Cutflows for all samples on EOS for $htag..."
  
  for fileName in ${Samples[@]}; do
      file=""
      for DIR in ${MXAODDIRS[@]}; do
        #[[ ! -z "$(eos ls $datasetDir/$htag/$DIR/$fileName 2>/dev/null)"  ]] && file="root://eosatlas.cern.ch/$datasetDir/$htag/$DIR/$fileName" && sampleDir=$DIR
        [[ ! -z "$(eos ls $datasetDir/$htag/$DIR/$fileName 2>/dev/null)"  ]] && file="$EOSMOUNTDIR/$datasetDir/$htag/$DIR/$fileName" && sampleDir=$DIR
      done
      #file="root://eosatlas.cern.ch/$datasetDir/$htag/$mcDir/$fileName"
      echo $file
      base=$(basename ${file})
      fileType=${fileName%.MxAOD*}
      cutFlowName=CutFlow_$fileType

      nFiles=$(eos ls $datasetDir/$htag/$sampleDir/$fileName | wc -l)
      if [[ $fileName =~ $DATANAME ]]; then
        root -l -q -b "$BASEDIR/AllCutflows/printCutflowData.c(\"${file}\")" 2>err.log 1> cutflows/${fileName}.txt
      else
        root -l -q -b "$BASEDIR/AllCutflows/printCutflow.c(\"${file}\",${nFiles},\"${cutFlowName}\")"  2>err.log 1> cutflows/${fileName}.txt
      fi
      sed -i'.og' "1d" cutflows/${fileName}.txt
      sed -i'.og' "s/^ *//g" cutflows/${fileName}.txt
      sed -i'.og' "s/Processing.*/                    $fileType/g" cutflows/${fileName}.txt
      cp cutflows/${fileName}.txt $BASEDIR/AllCutflows/cutflows/
  done
  

done
Samples=()
for DIR in ${MXAODDIRS[@]}; do
  Samples+=($(eos ls $datasetDir/$htagNew/$DIR/  ))
  #break
done

# make diff cutflows to compare old and new cutflows
for filename in ${Samples[@]}; do
  fileType=${filename%.MxAOD*}
  for DIR in ${MXAODDIRS[@]}; do
    [[ ! -z "$(eos ls $datasetDir/$htagNew/$DIR/$filename 2>/dev/null)"  ]] && fileNew="root://eosatlas.cern.ch/$datasetDir/$htagNew/$DIR/$filename" && sampleDir=$DIR
    #eos ls $datasetDir/$htag/$DIR/$fileName
    #echo $datasetDir/$htag/$DIR/$fileName
  done
  #echo $sampleDir
  oldCutflowName=$(eos ls $datasetDir/$htagOld/$sampleDir/ | grep ${fileType}.MxAOD)
  echo $fileType
  diffCutflowName=$(echo $filename | sed "s/h[0-9][0-9][0-9]/diff/g")
  #oldCutflowName=$(echo $filename | sed "s/h[0-9][0-9][0-9]/$htagOld/g")
  [[ -z "$oldCutflowName" ]] && echo $htagOld version of $fileType in $sampleDir does not exist! skipping...  && continue
  ptag=${filename%.h[0-9][0-9][0-9]*}
  ptag=${ptag#*MxAOD*.}
  oldptag=${oldCutflowName%.h[0-9][0-9][0-9]*}
  oldptag=${oldptag#*MxAOD*.}
  #echo $filename
  #echo $ptag
  #echo $oldCutflowName
  #echo $oldptag
  sed -i'.og' "1d" cutflows/${diffCutflowName}.txt
  #newCutflowName=$(echo $filename | sed "s/h[0-9][0-9][0-9]/$htagNew/g")
  $BASEDIR/AllCutflows/diffCutflow.py cutflows/${oldCutflowName}.txt cutflows/${filename}.txt && \
    sed -i'.og' "1 i\             $fileType" cutflows/${diffCutflowName}.txt
  [[ "$ptag" != "$oldptag" ]] && sed -i'.og' "1 i\ pTags are different! New is $ptag, old is $oldptag" cutflows/${diffCutflowName}.txt
  #[[ "$ptag" != "$oldptag" ]] && echo ptags are different!
  cp cutflows/${diffCutflowName}.txt $BASEDIR/AllCutflows/cutflows/
done
#rm cutflows/*.og
echo ended $0 at $(date)



