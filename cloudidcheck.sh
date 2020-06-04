#!/bin/bash
#
#    This script reports on all the cloud resources for a range of student Cloud User IDs within a region
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

scriptname="cloudidcheck"

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

  # Check Clusters

  echo "Clusters: " | tee -a $logfile
  
  if [ `ibmcloud ks clusters | grep -Ev 'OK|ID' | wc -l` -ge 1 ]; then
    ibmcloud ks clusters | grep -Ev OK | tee -a $logfile
  else
    echo "No Clusters" | tee -a $logfile
  fi

  echo >> $logfile

  # Check Namespaces

  echo "Namespaces: " | tee -a $logfile
  
  if [ `ibmcloud cr namespace-list | grep "No namespace" | wc -l` -eq 1 ]; then
    ibmcloud cr namespace-list | grep "No namespace" | tee -a $logfile
  else
    ibmcloud cr namespace-list | grep -Ev 'Listing|OK|^$' | tee -a $logfile
  fi

  echo >> $logfile

# Check IAM Service Instances

  echo "IAM Service Instances: " | tee -a $logfile

  if [ `ibmcloud resource service-instances | grep -Ev 'Retrieving|Getting|OK|Name|^$' | awk -F '  +' '{print $1}'| grep "No service instance found" | wc -l` -eq 1 ]; then
    ibmcloud resource service-instances | grep -Ev 'Retrieving|Getting|OK|Name|^$' | awk -F '  +' '{print $1}'| grep "No service instance found" | tee -a $logfile
  else
    rgservicelist=`ibmcloud resource service-instances | grep -Ev 'Retrieving|Getting|OK|Name|^$' | awk -F '  +' '{print $1}'`
    rgservicenum=`echo "$rgservicelist" | wc -l`
    for (( i = 1; i <= $rgservicenum; i++ ))
    do
      echo >> $logfile
      echo "IAM Service Instance: " | tee -a $logfile
      rgservicename=`echo "$rgservicelist" | sed -n ${i}p`
      echo $rgservicename | tee -a $logfile
      rgservicekeylist=`ibmcloud resource service-keys | grep -Ev 'Retrieving|Getting|OK|Name|^$' | awk -F '  +' '{print $1}'`
      echo "IAM Service Keys: " | tee -a $logfile
      echo $rgservicekeylist | tee -a $logfile
    done
  fi

  echo >> $logfile

  # Check Cloud Foundry Spaces

  echo "Cloud Foundry Spaces: " | tee -a $logfile

  ibmcloud account spaces | grep -Ev 'Invoking|Getting|OK|Name|^$' | awk -F '  +' '{print $1}' | tee -a $logfile

  echo >> $logfile

# Set up loop for spaces

  spacelist=`ibmcloud account spaces | grep -Ev 'Getting|OK|Name|^$' | awk -F '  +' '{print $1}'`
  spacenum=`echo $spacelist | wc -w`

  for (( s = 1; s <= $spacenum; s++ ))
  do
  spacename=`echo $spacelist | cut -d" " -f${s}`
  echo "Space:  " $spacename | tee -a $logfile
  echo >> $logfile

  ibmcloud target -o cldstd${useridnum}@us.ibm.com -s ${spacename}

  # Check Cloud Foundry Services & Service Keys

  echo "Cloud Foundry Services & Service Keys: " | tee -a $logfile

  if [ `ibmcloud service list | grep "No services found" | wc -l` -eq 1 ]; then
    ibmcloud service list | grep "No services found" | tee -a $logfile
  else
    servicelist=`ibmcloud service list | grep -Ev 'Invoking|Getting|OK|name|^$' | awk -F '  +' '{print $1}'`
    servicenum=`echo "$servicelist" | wc -l`
    for (( i = 1; i <= $servicenum; i++ ))
    do
      echo >> $logfile
      echo "Service: " | tee -a $logfile
      servicename=`echo "$servicelist" | sed -n ${i}p`
      echo $servicename | tee -a $logfile
      servicekeylist=`ibmcloud service keys "$servicename" | grep -Ev 'Invoking|Getting|name|^$'`
      echo "Service Keys: " | tee -a $logfile
      echo $servicekeylist | tee -a $logfile
    done
  fi

  echo >> $logfile

  # Check Cloud Foundry Apps

  echo "Cloud Foundry Apps: " | tee -a $logfile

  if [ `ibmcloud app list | grep "No apps found" | wc -l` -eq 1 ]; then
    ibmcloud app list | grep "No apps found" | tee -a $logfile
  else
    applist=`ibmcloud app list | grep -Ev 'Invoking|Getting|OK|name|^$' | awk -F '  +' '{print $1}'`
    routelist=`ibmcloud app list | grep -Ev 'Invoking|Getting|OK|name|^$' | awk -F '  +' '{print $6}'`
    appnum=`echo "$applist" | wc -l`
    for (( i = 1; i <= $appnum; i++ ))
    do
      echo >> $logfile
      echo "App: " | tee -a $logfile
      appname=`echo "$applist" | sed -n ${i}p`
      echo $appname | tee -a $logfile
      approute=`echo "$routelist" | sed -n ${i}p`
      echo "App Route: " | tee -a $logfile
      echo https://$approute | tee -a $logfile
    done
  fi

  # End of Space Loop
  echo >> $logfile
  echo >> $logfile
  done


  echo >> $logfile

  echo >> $logfile

  # Log out

  ibmcloud logout

  echo >> $logfile
  echo "---------------------" >> $logfile
  echo >> $logfile

done
