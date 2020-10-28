#!/bin/bash

DATABASE='home-assistant_v2.db'
SQLITE_STATUS=$(command -v sqlite3)

if [[ ${SQLITE_STATUS} == "" ]]
then
  echo "Missing sqlite3 package!"
  exit 1
fi

# read the options
TEMP=`getopt -o t:c:i:e:w:ES --long table:,item:,entity:,column:,where:,events,states -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -t|--table)
        TABLE=$2 ; shift 2 ;;
    -e|--entity)
        ENTITY_ID=$2 ; shift 2 ;;
    -c|--column)
        COLUMN=$2 ; shift 2 ;;
    -i|--item)
        ITEM=$2 ; shift 2 ;;
    -w|--where)
        WHERE=$2 ; shift 2;;
    -E|--events)
        EVENTS=:"TRUE" ; shift 1 ;;
    -S|--states)
        STATES=:"TRUE" ; shift 1 ;;
    #Default
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

if [[ ${EVENTS} != "" ]]
then
  COLUMN="event_data"
  TABLE="events"
  if [[ ${WHERE} == "" ]]
  then
    SQL_QUERY=$(sqlite3 ${DATABASE} "SELECT ${COLUMN} from ${TABLE} ORDER BY created DESC LIMIT 1")
  else
    SQL_QUERY=$(sqlite3 ${DATABASE} "SELECT ${COLUMN} from ${TABLE} where ${WHERE}")
  fi
elif [[ ${STATES} != "" ]]
then
  TABLE="states"
  COLUMN="attributes"

  SQL_QUERY=$(sqlite3 ${DATABASE} "SELECT ${COLUMN} from states where entity_id='${ENTITY_ID}' order by last_changed limit 1")
else
  echo "Select events or states (-e / -s)"
fi

GREP_JSON_ITEM=$(echo ${SQL_QUERY} | grep -Po "\"${ITEM}\": ( \"(.*?)\"|\"(.*?)\")" )
ITEM_VAL=$(echo $GREP_JSON_ITEM| cut -d'"' -f 4)
echo $ITEM_VAL
