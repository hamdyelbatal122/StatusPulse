
#!/bin/bash
#set -x
enfilevar_setup(){
	STATFILE=`echo $CURRHOME/StatusOutput`
	OUT=`echo $CURRHOME/today.html`
	CONFIG=`echo $CURRHOME/config/app.conf`
	INST_URLS=`echo $CURRHOME/config/instanceurl_file`
	INST_NAMES=`echo $CURRHOME/config/instance_names`
	XDATAFILE=`echo $CURRHOME/xdata.pid`
  LOGFILE=`echo $CURRHOME/log.out`
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
  LOGFILE=`echo $CURRHOME/log.out`
}

STARTXDATA=350
TILE='<rect class=status width=20 height=20 x=xdata y=ydata><title>version</title></rect>'
COMP='<text dx=xaxis dy=yaxis>comp</text>'
#ver_re='^[0-9]+([.][0-9]+)?$'
ver_re='^[0-9]+(.*)?$'

read_config() {
        CONFIG=`cat $CONFIG`;
        if [[ `echo $CONFIG` == *,* ]];
        then
                COMPURL=`echo $CONFIG | sed 's/[A-Za-z0-9_-/]*,//g'`;
        elif [[ `echo $CONFIG` == */* ]];
        then
                COMPURL=`echo $CONFIG`;
        elif ! ([[ `echo $CONFIG` == *,* ]] || [[ `echo $CONFIG` == */* ]]);
        then
                COMPURL=`cat $INST_URLS`
        else
                echo "<h1>Can't monitor the application. Config file is missing or corrupted.</h1>">>$OUT
                exit 1
        fi;
}

remove_vhost()
{
        if [ -f vhost_unknown* ]
        then
                rm vhost_unknown*
        fi
}

add_tile(){
        xdata=$1
        ydata=$2
        status=$3
        version=$4
        echo $TILE | sed "s/xdata/$xdata/g" | sed "s/ydata/$ydata/g" | sed "s/status/$status/g" |  sed "s/version/$version/g" >>$OUT
}


status_puller(){
ydata=5
xdata=$1
for line in $COMPURL
        do
        val=$(wget -S --timeout=1 --waitretry=1 --tries=3 --retry-connrefused "http://$line/version.html" 2>&1 | grep "HTTP/" | awk '{print $2}')
        if [[ $val == 200 ]]; then
                version_no=$(grep 'Version :' version.html|awk  '{print $3}'|awk -F '<' '{print $2}'|awk -F '>' '{print $2}')
                if ! [[ $version_no =~ $ver_re ]] ; then
                        add_tile $xdata $ydata "pass" "VERSION ISSUE"
                else
                        add_tile $xdata $ydata "pass" $version_no
                fi
                rm -rf version.html*
         else
		         echo "$line, Error">>$LOGFILE
             add_tile $xdata $ydata "fail" "ERROR"
             rm -rf version.html*
        fi
        ydata=$((ydata+30))
done
}

post_executor(){
  xdata=$1
  echo $((xdata+30))>$XDATAFILE
  remove_vhost
}

microexecutor(){
	xdata=$1
	read_config
	status_puller $xdata
	post_executor $xdata
}


getxdata(){
	CSTTIME=`TZ=":US/Central" date +%Y-%m-%d-%H:%M`
	REGEXTZ="^([^-]+)-(.*)-(.*)-(.*):(.*)$"
	INITIALPIXELVALUE=60
	[[ $CSTTIME =~ $REGEXTZ ]] && currhr="${BASH_REMATCH[4]}" && currmin="${BASH_REMATCH[5]}"
	currhr=$((10#$currhr*INITIALPIXELVALUE))
	xdata=$((STARTXDATA+currhr))
	if [ "$currmin" -ge 30 ]
	then
		xdata=$((xdata+30))
	fi
}

executor(){
    getxdata
    if [[ "$xdata" -ge 350 && "$xdata" -le 1760 ]]
    then
	     microexecutor $xdata
    else
	     exit 1
    fi
}

appmain_addtile(){
  if [ -f ${OUT} ]
  then
    executor
  else
    exit 1
  fi
}

instmain_setup(){
	# if instance config exists, extract the component details and store in variable
	if ls config/*.insta >/dev/null 2>&1;then  instacomp=`ls config/*.insta | awk -F/ '{print $NF}' | sed 's/\.insta//g'`; else echo "Instance file doesnt exists"; exit 0; fi
	# for-each component, check if there is already a directory exists; else create one and add the tile
	for i in $instacomp;
	  do
	    if [ -d $i ]; then
        	# echo "Checking directory"
		    :
	    else
          # echo "$i directory doesn't exist"
          continue;
        # mkdir $i
	    fi
    	  ienfilevar_setup $i
	  	appmain_addtile
	done
}

appmain_setup(){
	enfilevar_setup
	appmain_addtile
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
