#!/bin/bash

organization="user-group" #Organization Name as showed in DevOps URL
project="API%20Share" #Organization Name as showed in DevOps URL
path="/home/tibco/Workspace/APIShare/Backup" #Your local path where the Backup will be stored
patBase64="" #A base64 converted PAT



echo "Starting DevOps Backup ..."
echo "Organization: ${organization}"
echo "Project: ${project}"
echo ""

echo "Backing up repositories"

if [[ -d $path/repos ]]; then
	cd $path/repos
else 
	mkdir $path/repos
fi

reposData=$(curl -s -X GET "https://dev.azure.com/${organization}/${project}/_apis/git/repositories?api-version=6.1-preview.1" --header "Authorization: Basic ${patBase64}")
reposLenght=$(echo $reposData | jq -r .count)
echo "I found ${reposLenght} repositories"

for k in $(echo $reposData | jq -r '.value | .[].name'); do

	if [[ -d $k ]]; then
		cd $k
		git pull
		cd ..
		echo "#########################################"
		echo "Updated repository ${k}"
		echo "#########################################"
	else
		git clone "https://${organization}@dev.azure.com/${organization}/${project}/_git/${k}"
		echo "#########################################"
		echo "Cloned repository ${k}"
		echo "#########################################"
	fi

done
echo ""


echo "Backing up Variable Groups ..."

if [[ ! -d $path/variableGroups ]]; then
	mkdir $path/variableGroups
fi

variableGroupsData=$(curl -s -X GET "https://dev.azure.com/${organization}/${project}/_apis/distributedtask/variablegroups?api-version=6.0-preview.2" --header "Authorization: Basic ${patBase64}")

for i in $(echo $variableGroupsData | jq -r '.value | .[].createdOn'); do
	echo $i
	echo $variableGroupsData | jq -r --arg I "${i}" '.value[] | select(.createdOn==$I)' > $path/variableGroups/$i.json
	rename=$(echo $variableGroupsData | jq --arg I "${i}" '.value[] | select(.createdOn==$I) | .id')
	mv $path/variableGroups/$i.json $path/variableGroups/$rename.json
done
echo ""

echo "Backing Up Task Groups ..."

if [[ ! -d $path/taskGroups ]]; then
	mkdir $path/taskGroups
fi

taskGroupsData=$(curl -s -X GET "https://dev.azure.com/${organization}/${project}/_apis/distributedtask/taskgroups?api-version=6.0-preview.1" --header "Authorization: Basic ${patBase64}")

for j in $(echo $taskGroupsData | jq -r '.value | .[].name'); do
	echo $taskGroupsData | jq --arg J "${j}" '.value[] | select(.name==$J)' > $path/taskGroups/$j.json
done
echo ""

echo "End of DevOps Backup"





