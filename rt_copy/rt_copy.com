#!/bin/tcsh -f
#####************************************************************************************#####
#Description: This program is used to copy data from K2 computer to cryogpu.
#             run it from your /data/user/
#	      set "mydir" (the dir in cryogpu)  and "all_mrcfiles" (the dir on K2) to the right path.
#	      it will make the new dir if not exist. 
#	      for .mrc file it will change the extetion to .mrcs to fit Relion.
#             modify from:
#             http://www.mrc-lmb.cam.ac.uk/kzhang/useful_tools/
#
#Author: Elad Binshtein 10312017 
#####************************************************************************************#####
#Tips: 
#To stop it use this command 'touch ALL_STOP' 'touch all_stop'
#it will still finish the current micrograph and then stop before the next micrograph
#if you rerun the script on the same directory make sure to delete the "all_stop" file !!!!
#####************************************************************************************#####zz

set all_mrcfiles="/raidx/Jackson/*mrc" #the K2 dir
set mydir="/data/newtest/" #the cryogpu dir
if ( ! -d $mydir ) then
   mkdir -p $mydir
endif

##################################################################################################################
##############################   End of user input   #############################################################
##################################################################################################################

while ( 1 )

set allmrcf=`ls $all_mrcfiles`


foreach mrcf ($allmrcf)

if ( -f ALL_STOP || -f rcync_STOP || -f all_stop ) then
exit
endif

set root=`basename $mrcf .mrc`

if ( -f ${root}_processing.log ) then
continue
else
echo "" > ${root}_processing.log
endif


if (  -f $mydir${root}.mrcs &&  -s $mydir${root}.mrcs &&  -Z $mydir${root}.mrcs > 2278237820 && $mydir${root}.mrcs == $mrcf  ) then
#if the file already exists non-empty and full size and equal to the source, it will not do anything
echo "$mrcf already processed, automatically skipped."
continue


else
##### copy ####
echo "start in `date` to copy `du -h $mrcf`  to $mydir .... "|tee -a copy.log
cp  $mrcf $mydir$root.tmp  #copy as temp file so other job like Relion2.0 wouldn't start until transfer is done 
mv $mydir$root.tmp $mydir$root.mrcs
echo "finish in `date`"
endif


rm -f ${root}_processing.log

end

echo ......................................................................
sleep 120s

end
#end while
