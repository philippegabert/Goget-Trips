#!/bin/bash


usage() {
  echo -e "Usage:\n" \
    "\t$0 -u <User ID> -p <User Password> [-f <Target Folder> -c <Cookie file>]\n\n" \
    "\t<User ID>: Your Goget user identifier (ex: 12345678)\n" \
    "\t<User Password>: Your Goget user password. If not passed as argument, will ask for user input\n" \
    "\t<Target Folder>: The folder you want to save the export to.\n" \
    "\t<Cookie file>: Temporary file where to save the cookie file to (Default: /tmp/cookies_goget) \n" \
   1>&2;
  exit 1;
}

#Misc conf
TARGET_FOLDER=GoGet/
COOKIES_TMP=/tmp/cookies_goget
USER_ID=
USER_PWD=

OPTS=`getopt u:,p:,f:,c: $*`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
#echo "$OPTS"
eval set -- "$OPTS"
NEWLINE=$'\n'
while true; do
case "$1" in
  -u ) USER_ID="$2" ; shift 2 ;;
  -p ) USER_PWD="$2" ; shift 2 ;;
  -f ) TARGET_FOLDER="$2" ; shift 2 ;;
  -c ) COOKIES_TMP="$2" ; shift 2 ;;
  -- ) shift; break ;;
  * ) break ;;
esac
done

if [ -z "${USER_ID}" ]; then
    echo "User id is missing !"
    usage
fi
if [ -z "${USER_PWD}" ]; then
    echo "Please enter password"
    read -s USER_PWD
fi

#Headers
HEADER_ACTIVITY_REPORT="Booking/Transaction ID,Driver Name,Vehicle,Registration,Pod(parking spot),Trip reason,Booking start,Booking end,Hours booked,Time charge,Km travelled,Km free,Km charge,Damage Cover,Location charge,Fines,Fees,Credits,Tolls,TOTAL(incl GST),Payment,Total DUE,"
HEADER_OTHER_FEES="Date,Type,Summary,Cost(incl GST),"


# FUNCTIONS
login(){
  #Login and getting cookies:
  echo Trying to login...
  http_code=`curl --write-out '%{http_code}' --silent --output /dev/null -X POST -H "Content-Type: application/x-www-form-urlencoded" -d "vUser=$USER_ID&vPwd=$USER_PWD&LoginSubmit=1" -c $COOKIES_TMP https://app.goget.com.au/bookings/login.php`
  if [ $http_code = 302 ] ; then
    echo "Login OK !"
  else
    echo "Error while login... Are you sure of the user name and password?"
    exit
  fi
}

download_data () {
  type_row="activity_report"
  i=0
  while read line;
    do
      if [ "$line" != "$HEADER_ACTIVITY_REPORT" -a "$line" != "$HEADER_OTHER_FEES" -a "${line:0:19}" != "Activity Report for" ] ; then
        if [ "$line" = "Other Fees and Credits" ]
        then
              #Changing the type of parser and ignoring this row
              type_row="other_fees"
        else
              echo $line >> "$TARGET_FOLDER"/$type_row.csv
              ((i++))
        fi
      fi
    done < <(curl  -sS -b $COOKIES_TMP https://app.goget.com.au/bookings/MyInvoicesCSV.php?start_time=$START_DATE&end_time=$END_DATE );
}

# ACTUAL SCRIPT
login
mkdir -p $TARGET_FOLDER
echo $HEADER_ACTIVITY_REPORT > "$TARGET_FOLDER"/activity_report.csv
echo $HEADER_OTHER_FEES > "$TARGET_FOLDER"/other_fees.csv

# Here we get the list of months since the user got his account created. (and start/end timestamp to query the data)
timestamps=`curl -sS -b $COOKIES_TMP https://app.goget.com.au/bookings/account-details | grep "var csvBoundaryTimes" | sed -e 's/var csvBoundaryTimes = //' -e 's/;//'`

echo $timestamps | jq -r '. | keys[]' | while read year; do
   # Years
   echo '########## Fetching data for year ' $year ' ########## '
   echo $timestamps | jq -r '.["'$year'"] | keys[]' | while read month; do
     month_formatted=`printf '%02d' $month`
     echo 'Fetching data for ' $month_formatted/$year
     START_DATE=`echo $timestamps | jq -r '.["'$year'"]["'$month'"][0]'`
     END_DATE=`echo $timestamps | jq -r '.["'$year'"]["'$month'"][1]'`
     download_data
  done
done

echo "Downloading data for last month..."

if date --version >/dev/null 2>&1 ; then
  # Using GNU date
  START_DATE=`date -d "-1 month -$(($(date +%d)-1)) days today 0" +'%s'`
  END_DATE=`date -d "-$(date +%d) days today 23:59:59" +'%s'`
else
  # Not using GNU date (BSD for MacOS)
  START_DATE=`date -v1d -v-1m -v0H -v0M -v0S +'%s'`
  END_DATE=`date -v31d -v-1m -v23H -v59M -v59S +'%s'`
fi

download_data

echo "Deleting cookie file..."
if [ -f $COOKIES_TMP ] ; then
    rm $COOKIES_TMP
fi

echo Finished !
