#!/bin/bash
#
#    This script deploys a free Kubernetes cluster and registry namespace in each of a range of 
#    student Cloud User IDs within a region
#    It prompts for:
#        - First ID number in range
#        - Last ID number in range (Use the same number for single ID)
#        - Region
#
#    Use a companion shell script preferably in the same directory to populate an array
#    called "key" with an API Key for each User ID. The statements in the companion 
#    script should be in the form:
#         key[<ID number>]=<API Key>
#
#

scriptname="cloudidbuild"

keyscript="./keys.sh"


# Load apikey and region arrays

declare -a key

source ${keyscript}

declare -a region

region[1]=us-south
region[2]=eu-de
region[3]=eu-gb
region[4]=au-syd
region[5]=us-east
region[6]=jp-tok

declare -a regname

regname[1]="Dallas"
regname[2]="Frankfurt"
regname[3]="London"
regname[4]="Sydney"
regname[5]="WashingtonDC"
regname[6]="Tokyo"

declare -a ksregion

ksregion[1]=us-south
ksregion[2]=eu-central
ksregion[3]=uk-south
ksregion[4]=ap-south
ksregion[5]=us-south
ksregion[6]=ap-south

# Set API Endpoint

ibmcloud api --unset
ibmcloud api cloud.ibm.com

# Update CLIs

ibmcloud plugin update kubernetes-service 
ibmcloud plugin update container-registry 

echo
echo

# get user numbers range

printf "Enter First User Number: (No Leading Zeros)\n"
read firstnum
 
printf "\n\n"

if [ ${firstnum} -le 9 ]; then
   firstidnum="0${firstnum}"
else
   firstidnum=${firstnum}
fi

printf "Enter Last User Number: (No Leading Zeros)\n"
read lastnum

if [ ${lastnum} -le 9 ]; then
   lastidnum="0${lastnum}"
else
   lastidnum=${lastnum}
fi

printf "\n\n"

# Get Cloud Foundry regions

for (( r=1; r<=6; r++ ))
do
printf "${r}  ${regname[r]}\n"
done

printf "\n\n"
printf "Enter region number: \n"
read regwork

# Create log file name

logfile=${scriptname}-cldstd${firstidnum}-cldstd${lastidnum}-`date +%F`-`date +%H%M%S`-${regname[$regwork]}.log

date > $logfile
echo ${regname[$regwork]} >> $logfile
echo >> $logfile

# Loop Through User Ids

for (( usernum=firstnum; usernum<=lastnum; usernum++ ))
do

  # echo ${key[$usernum]}
  thiskey=${key[$usernum]}

  if [ ${usernum} -le 9 ]; then
     useridnum="0${usernum}"
  else
     useridnum=${usernum}
  fi


  # Log in

  ibmcloud login --apikey $thiskey -r ${region[$regwork]}

  ibmcloud target -o cldstd${useridnum}@us.ibm.com
#  ibmcloud target --cf
  ibmcloud target -g Default
#  ibmcloud ks region set --region ${ksregion[$regwork]}
  ibmcloud target | grep User >> $logfile

  echo >> $logfile

  # Create Cluster

#  echo "Create Cluster: " | tee -a $logfile
  
  if [ `ibmcloud ks clusters | grep -v OK | wc -l` -eq 1 ]; then
#    ibmcloud ks cluster-create --name cldstd${useridnum}
#    ibmcloud ks cluster-create --name cloudcluster
    ibmcloud ks cluster create classic --name cloudcluster 
    sleep 5
    ibmcloud ks clusters | grep -Ev 'OK|Name' | tee -a $logfile
  else
    ibmcloud ks clusters | grep -Ev 'OK|Name' | tee -a $logfile
  fi

  echo >> $logfile

  # Create Container Registry Namespace

  echo "Create Namepace: " | tee -a $logfile
  
  if [ `ibmcloud cr namespace-list | grep -v OK | grep -v Listing | grep -v "No namespaces exist" | grep -v "Create a namespace" | wc -l` -eq 2 ]; then
    ibmcloud cr namespace-add cldstd${useridnum}-ns | tee -a $logfile
    sleep 5
    ibmcloud cr namespace-list | grep -Ev 'OK|Listing' | tee -a $logfile
  else
    ibmcloud cr namespace-list | grep -Ev 'OK|Listing' | tee -a $logfile
  fi

  echo >> $logfile

  # Log out

  ibmcloud logout

  echo >> $logfile
  echo "---------------------" >> $logfile
  echo >> $logfile

done
