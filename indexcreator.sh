
#!/bin/bash
#set -x

enfilevar_setup(){
	STATFILE=`echo $CURRHOME/StatusOutput`
	OUT=`echo $CURRHOME/today.html`
	CONFIG=`echo $CURRHOME/config/app.conf`
	INST_URLS=`echo $CURRHOME/config/instanceurl_file`
	INST_NAMES=`echo $CURRHOME/config/instance_names`
	XDATAFILE=`echo $CURRHOME/xdata.pid`
}

ienfilevar_setup(){
	instance=$i;
	CONFIG=`echo $CURRHOME/config/$instance.insta`;
	CURRHOME=`echo $CURRHOME/instances/$i`;
	STATFILE=`echo $CURRHOME/StatusOutput`
	OUT=`echo $CURRHOME/index.html`
	INST_URLS=`echo $CURRHOME/config/$i'_instanceurl_file'`
	INST_NAMES=`echo $CURRHOME/config/$i_'instance_names'`
	XDATAFILE=`echo $CURRHOME/xdata.pid`
}

envar_setup(){
	avgspacefortile=32
	height=`expr \`cat $CONFIG | wc -l\` \* $avgspacefortile`
	FRAME='<!DOCTYPE html><html lang="en"><head><title>App Mon</title><link rel="icon" type="image/x-icon" href="favicon.ico" /><meta http-equiv="content-type" content="text/html; charset=UTF-8"></meta><meta http-equiv="refresh" content="30"></meta></head><style>body{background-color:black}h1{Color:white}.pass{fill:green}.fail{fill:red}.warn{fill:orange}.status{fill:gray}svg{font-size:14px;fill:#fff;background-color:black;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif,"Apple Color Emoji","Segoe UI Emoji","Segoe UI Symbol"}text.month-90deg{transform:rotate(90deg)}</style><body><div><div>'
	SIZEDEF="<svg width=\"1900\" height=\"$height\">"
	HEADER=`echo $FRAME $SIZEDEF`
	FOOTER='</svg></div></div></div></body></html>'
	GTRANSFORM='<g transform="translate(0, 40)">'
	CLOSEG='</g>'
	TILE='<rect class=status width=20 height=20 x=xdata y=ydata v=version />'
	CLOCK='<text x=xtimloc y=ytimloc>hour:00</text>'
	COMP='<text dx=xaxis dy=yaxis>comp</text>'
	ver_re='^[0-9]+([.][0-9]+)?$'
	CURRDATE=`date -d "-1 days" +%Y%m%d`
}

read_config() {
	CONFIG=`cat $CONFIG`;
	if [[ `echo $CONFIG` == *,* ]];
	then
		COMPHEADER=`echo $CONFIG | sed 's/,[A-Za-z0-9.:-]*//g' | sed 's/\/[A-Za-z0-9-]*//g' |  sed 's/fulfillment-//g'`;
		COMPURL=`echo $CONFIG | sed 's/[A-Za-z0-9_-/]*,//g'`;
	elif [[ `echo $CONFIG` == */* ]];
	then
		COMPHEADER=`echo $CONFIG | sed 's/[A-Za-z0-9.:-]*\///g' | sed 's/fulfillment-//g'`;
		COMPURL=`echo $CONFIG`;
	elif ! ([[ `echo $CONFIG` == *,* ]] || [[ `echo $CONFIG` == */* ]]);
	then
		COMPHEADER=`cat $INST_NAMES`
		COMPURL=`cat $INST_URLS`
	else
		echo "<h1>Can't monitor the application. Config file is missing or corrupted.</h1>">>$OUT
		exit 1
	fi;
}

xdatafile_checker(){
if [ -f ${XDATAFILE} ]
then
        rm $XDATAFILE
fi
}

statfile_checker(){
if [ -f ${STATFILE} ]
	then
		rm $STATFILE
	fi
}

remove_vhost()
{
	if [ -f vhost_unknown* ]
	then
		rm vhost_unknown*
	fi
}

env_check(){
if [ -f ${OUT} ]
  then
	index_end
	if [[ "$OUT" =~ '/instances/' ]]
	then
		instarchpath=`echo "$OUT" | rev | cut -d"/" -f2- | rev`; 
		instarchpath=$instarchpath/$CURRDATE.html; 
		mv $OUT $instarchpath
	else
		mv $OUT $CURRDATE.html
	fi
	xdatafile_checker
  fi
}

index_start(){
	echo $HEADER>>$OUT
	echo $GTRANSFORM>>$OUT
}

get_compnt_list()
{
	apps=`echo $COMPHEADER`
}

index_addcomp(){
  xaxis=15
  yaxis=20
  xdata=350
  ydata=5
  for app in $apps
    do
      echo $COMP | sed "s/comp/$app/g" | sed "s/xaxis/$xaxis/g" | sed "s/yaxis/$yaxis/g">>$OUT
      yaxis=$((yaxis+30))
    done

  xtimloc=360
  ytimloc=-10
  for hour in {00..23}
    do
       echo $CLOCK |  sed "s/hour/$hour/g" | sed "s/xtimloc/$xtimloc/g" | sed "s/ytimloc/$ytimloc/g">>$OUT
       xtimloc=$((xtimloc+60))
    done
}

index_addafterblack(){
  for xdata in {1800..1850..30}
    do
      echo "<rect width=20 height=20 fill="#000000" x=$xdata y=0 />">>$OUT
    done
}

index_end(){
   echo $CLOSEG>>$OUT
   echo $FOOTER>>$OUT
}

executor(){
	envar_setup
	env_check
	statfile_checker
	index_start
	read_config
	get_compnt_list
	index_addcomp
}

instmain_setup(){
	# if instance config exists, extract the component details and store in variable
	if ls config/*.insta >/dev/null 2>&1;then  instacomp=`ls config/*.insta | awk -F/ '{print $NF}' | sed 's/\.insta//g'`; else echo "Instance file doesnt exists"; exit 0; fi
	# for-each component, check if there is already a directory exists; else create one
	for i in $instacomp;
	  do
	    if [ -d $i ]; then
		:
	        # echo "Component : $i"
		# echo "Instance directory exists. Ignoring this iter";
	# 	Check the index.html file for that folder
	#	if [ -f "$i/index.html" ]; then
	#		echo "Both Instance directory and index.html already exits."
		# archive the index.html
	#		index_end
	#	fi
		# Create index.html in - $i/index.html
	    else
	      # echo "Instance directory doesn't exists";
		# Create directory and index file for that folder
	      mkdir $i
	    fi
  	  ienfilevar_setup $i
	  executor
	done
}

appmain_setup(){
	enfilevar_setup
	executor
}

main(){
	EXEFOR=$1
	if [ "$EXEFOR" == "i" ]
	then
	   # echo "It is for instance level"
 	   instmain_setup
	elif [ "$EXEFOR" == "a" ]
	then
	   # echo "It is for application level"
	    appmain_setup
	else
	   # echo "Unknown command. Exiting terminal"
	   exit 0
	fi
}

cd "$(dirname "$0")";
CURRHOME=`pwd`
if [ $# -eq 1 ]
then
	EXEFOR=$1
elif [ $# -eq 0 ]
then
	# echo "it is for all"
	appmain_setup
else
	# echo "Unauthorized usage.Exiting the command line."
	exit 0
fi
main $EXEFOR