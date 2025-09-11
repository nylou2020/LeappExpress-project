#!/bin/sh
#echo "Tier Definition:"
#echo " Tier 0 - no risk factors detected in the leapp-report file."
#echo " Tier 1 - 1 or more low / info risk factors detected;"
#echo " no inhibitors & no high risk factors in the leapp-report file."
#echo " Tier 2 - 1 or more high / med risk factors detected in the leapp-report file."
#echo " no inhibitors factors detected in the leapp-report file."
#echo " Tier 3 - 1 or more inhibitor risk factors detected in the leapp-report file."
#echo ""

Host=`hostname -s`
Tier=0
TierSet=0
RptFile="/var/log/leapp/leapp-report.txt"
OutFile="/var/log/leapp/RF_Summary.txt"

if [ ! -f $RptFile ]; then
   MSG="The Leapp Report [${RptFile}] does not exist. Unable to summarize Risk factor counts."
   /usr/bin/echo "${MSG}" | tee $OutFile
   exit 0
fi

InhibCnt=`/usr/bin/grep "Risk Factor:" $RptFile | grep inhibitor | wc -l`
HighCnt=`/usr/bin/grep "Risk Factor:" $RptFile | grep high | grep -v inhibitor | wc -l`
MedCnt=`/usr/bin/grep "Risk Factor:" $RptFile | grep medium | wc -l`
LowCnt=`/usr/bin/grep "Risk Factor:" $RptFile | grep low | wc -l`
InfoCnt=`/usr/bin/grep "Risk Factor:" $RptFile | grep info | wc -l`

#echo "InhibCnt= $InhibCnt  HighCnt= $HighCnt  MedCnt= $MedCnt   LowCnt= $LowCnt  InfoCnt= $InfoCnt"
Sum=$((InhibCnt + HighCnt + MedCnt + LowCnt + InfoCnt))
#echo "Sum= $Sum"
##############################
# Tier Classification Logic
##############################
# Test for Tier 0 or Tier 3 conditions
########################################
if [[ $Sum -eq 0 ]]; then
   Tier=0
   TierSet=1
   MSG="Tier0 - No risk factors detected in the report file, $RptFile"
   echo "${MSG}" > $OutFile
elif [[ $InhibCnt -gt 0 ]]; then
   Tier=3
   TierSet=1
      MSG="Tier3 - 1 or more inhibitor risk factors detected. There could also be high/med/low/info risk factors."
   echo "${MSG}" > $OutFile
fi
#echo "Tier= $Tier TierSet= $TierSet"
Sum=0
Sum1=0

# If TierSet flag is still 0 then Test for a Tier 1 or Tier 2 condition.
###################################################################
if [ $TierSet -eq 0 ]; then
   #echo "TierSet is still 0; Determine if Tier 1 or Tier 2"
   Sum=$((HighCnt + MedCnt))
   Sum1=$((LowCnt + InfoCnt))
  #echo "Sum= $Sum Sum1= $Sum1"
   if [ $Sum -gt 0 ]; then
      MSG="Tier2 - detected 1 or more High / Med risk factors. No inhibitors. There could be low / info risk factors."
      echo "${MSG}" > $OutFile
      Tier=2
      TierSet=1
   elif [ $Sum1 -gt 0 ]; then
      MSG="Tier1 - detected 1 or more Low / Info risk factors. No inhibitor / high / med risk factors."
      echo "${MSG}" > $OutFile
      Tier=1
      TierSet=1
   fi
fi

if [ $TierSet -eq 0 ]; then
   echo "Error determining Tier from risk factor counts with report file."
   exit 1  ## maybe echo a mesg or set a flag
fi

# Get Current Host OS Version
#############################
OSver=`grep VERSION_ID /etc/os-release | cut -d\" -f2`

# Stats Summary
#####################
if [ ! -s $OutFile ]; then
   # File does't exist or at size 0 bytes. Append starting header to file.
   ( printf "%34s %15s\n" OS Inhi- ) | tee -a $OutFile
   ( printf "%-15s %-15s %-5s %-6s %-7s %-5s %-5s %-5s %s\n" Date/Time Hostname Ver Tier bitor High Med Low Info ) | tee -a $OutFile
fi
DateTime=`date +%Y%m%dT%H%M%S`
( printf "%15s %-15s %-5s Tier%-2s %-7s %-5s %-5s %-5s %s \n" $DateTime $Host $OSver $Tier $InhibCnt $HighCnt $MedCnt $LowCnt $InfoCnt ) | tee -a $OutFile
