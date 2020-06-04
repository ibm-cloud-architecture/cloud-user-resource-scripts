<h1 align="center">
IBM Cloud User ID Resource Management Scripts
</h1>

<p align="left">
    <a href="https://github.com/ibm-cloud-architecture/cloud-user-resource-scripts/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="IBM Cloud User ID Resource Management Scripts is released under the Apache-2.0 license" />
  </a>
</p>

# cloud-user-resource-scripts
Scripts to create, query, and destroy cloud resources for a range of user ids

## Overview

This set of scripts were originally written to help automate the setup for, management of, and cleanup of, a range of IBM Cloud Public user ids
allocated to students for courses I was teaching. Each student was allocated a user id for hands-on lab exercises. The students would start with an existing free (classic) kubernetes cluster and cluster registry namespace. During the course, they would create other resources following the lab exercises, sometimes naming them as instructed and sometimes not. At the end of the class, I needed to quickly clear out any resources the student had created in preparation for the next class.

The set of existing user ids managed by the scripts follow the naming convention `cldstdXX@us.ibm.com`, where `XX` is the user id number.

The 4 scripts in this repo are as follows:
- `cloudidbuild.sh` - Creates a kubernetes cluster and cluster registry namespace in each user id.
- `cloudidcheck.sh` - Reports the existing cloud services, applications, and other resources in each user id. The script can deal with any number of instances of a given resource, not just one. It should also be able to deal with the situation where a resource name contains a space.
- `cloudidclean.sh` - Removes all cloud services, applications, and other resources in each user id. The script can deal with any number of instances of a given resource, not just one. It should also be able to deal with the situation where a resource name contains a space.
- `keys.sh` - Contains an array containing an API Key for each of the user ids you want to manage.

The scripts use the IBM Cloud Public command line interface (CLI), but could be adapted to work in other cloud environments. They authenticate each user id using API keys stored in an array in the companion script `keys.sh`. The use of API keys allows the scripts to keep working without worrying about passwords, which I was constantly changing for each class.
The scripts report their results to the screen and also to a time-stamped log file. A sample log file for the `cloudidcheck.sh` script is provided. 

## Script Flow

Each script follows the same flow:

1. If there is an update available for the `ibmcloud` CLI, the user is prompted if they want to install the update.

2. Sets the API endpoint to cloud.ibm.com

3. Command line plugins for the `kubernetes-service` and `container-registry` CLIs are updated if necessary.

4. The user is prompted for the first user id number in the range and the last user id number in the range.

5. The user is prompted for the region to work in.

6. The script loops through the range of user ids, creating resources, reporting resources, or deleting resources depending on which script is used.

## Potential Modification Requirements

These scripts are provided as is, in the hope that they might be useful to others. They can be adapted to a wide range of uses and environments. Here is a list of required or potential modifications:

1. The scripts use the CLI for IBM Cloud. The commands could be switched out with the CLI for any cloud environment.

2. The user id naming convention is `cldstdXX@us.ibm.com`, where `XX` is the user id number. The scripts would need to be adapted for other user id naming conventions. The user id naming convention is hard coded in the scripts, but only referenced 3 or 4 times. The user id naming convention could easily be captured in a variable for more extensibility.

3. The array in `keys.sh` needs to be populated with the user API Keys, login tokens, passwords or other authentication artifact.

4. The resources created, reported or destroyed could be modified per user requirements.

5. There are no arguments required for any of the scripts. They prompt for the information they need. The scripts could of course be modified to receive arguments for this information.

## Script Author

Dave Thiessen - dthiesse@us.ibm.com

Feel free to contact me for any questions or to discuss potential other uses.