#!/bin/bash
#set -x

check_folder(){
	dir=$1
	if [[ -z ${dir} ]];
	then
		return True
	else
		return False
	fi
}

# poll for .conf file & get the list of apps 
read_conf()
{
	apps=`cat app.conf | awk -F'/' '{print $1}'` 
}

# create DIR 
create_dir() 
{
	for app in $apps
	do
		if [[ -z ${app} ]];
		then
			mkdir $app
		fi

		if [[-z ${app}/url_file ]];
		then
			$app
			cp direct_mon.sh start_`echo $app`.sh 

		fi
	done	
}

# write the below list of files inside directory
	# App names 	instance_names
	# direct URLs	url_file
	
# copy the start-`app_name`.sh into the DIR
# create DIR 
copy_executor() 
{
	if [[-z ${app}/url_file_${app} ]];
		then
			mkdir $app
	fi

}

# start the script as sub-process 


