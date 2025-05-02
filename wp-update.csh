#!/bin/csh -xf 

# ex. 
# Home Directory: /home/userid/
# Backup Directory: /home/userid/backup
# Backup Script Directory: /home/userid/backup/bin

set SERVER_USERID = "userid"
set BACKUP_DAYS = 7
# "tar.xz", "tar.bz2","tar.gz","zip"
set COMPRESS_TYPE = "tar.gz"
set base_dir = "/home/${SERVER_USERID}/backup"
set logs = "$base_dir/logs"
set settings = "$base_dir/bin/wp-backup-targets.dat"
set backup_base_dir = "${base_dir}/backwpup"
set LOG_FILE = "$logs/`date +%Y%m%d`.log"
set WP_CLI  = "${base_dir}/bin/wp"
if ( ! -f "$WP_CLI" ) then
 echo "Cannot found WP-CLI command in ${WP_CLI}"
 exit
else
 $WP_CLI cli update --yes
endif

# If "Apcu manager" plugin is installed in a WordPress, it will be temporarlily disabled while the upload process.
set Disable_OBJECT_CACHE = "${WP_CLI} apcu settings disable object-caching --yes"
set Enable_OBJECT_CACHE =  "${WP_CLI} apcu settings enable object-caching"
set STATUS_OBJECT_CACHE =  "${WP_CLI} apcu status"
set WP_EXPORT = "${WP_CLI} db export --default-character-set=utf8mb4"
setenv LC_ALL ja_JP.UTF-8

if ( ! -d "$base_dir" ) then
  mkdir $base_dir
  chmod 700 $base_dir
endif
if ( ! -d "$logs" ) then
  mkdir -p $logs
endif

# Folder Check
if ( ! -d "$base_dir" ) then
  echo "Please create ${base_dir} folder, first"
  exit
endif

# speficied to taget db.

set target_dbs = "`grep -v '#' $settings`"

foreach target_db($target_dbs)

if("$target_db" == "") then
 goto usage
endif

## Pick up targets

set SEP_CHECK = `echo $target_db | awk '{num=split($0,arr,":"); print num;}'`

if ("$SEP_CHECK" != 5) then
  goto usage
endif

set WP_NAME = `echo $target_db | awk -F':' '{print $1}'`
set BK_DAYS  = `echo $target_db | awk -F':' '{print $2}'`
set LANG_FLAG  = `echo $target_db | awk -F':' '{print $3}'`
set COMPRESS  = `echo $target_db | awk -F':' '{print $4}'`
set WP_DIR  = `echo $target_db | awk -F':' '{print $5}'`

if( ! -d "$WP_DIR" ) then
  echo "Cannot found $WP_DIR folder"
  goto usage
endif

if( "$BK_DAYS" == "" ) then
  set BK_DAYS = $BACKUP_DAYS
else
  expr "$BK_DAYS" + 1 >& /dev/null
  set ret = $?
  if( $ret < 2 ) then
    if($BK_DAYS < 1) then
	set BK_DAYS = $BACKUP_DAYS
    endif
  else
    set BK_DAYS = $BACKUP_DAYS
  endif
endif

if ( ! ( "$COMPRESS" == "tar.gz" || "$COMPRESS" == "tar.bz2" || "$COMPRESS" == "tar.xz" || "$COMPRESS" == "zip" ) ) then
  set COMPRESS = $COMPRESS_TYPE
endif

set BACKUP_FILE = "backup_`date +%Y-%m-%d_%H-%M`.${COMPRESS}"

## DELETE OLD Backups
find $backup_base_dir/$WP_NAME/ -name "*.$COMPRESS" -type f -mtime +${BK_DAYS} | grep -v manually | awk '{print "rm -f "$0}' | sh

set backup_dir = "${backup_base_dir}/$WP_NAME"

if ( ! -d "$backup_dir" ) then
  mkdir -p $backup_dir
endif

cd $WP_DIR 
echo "---" >> $LOG_FILE
echo "$WP_NAME maintenance start..." >> $LOG_FILE
echo "" >> $LOG_FILE
echo "Start Log at `date +%Y%m%d.%H:%M:%S`" >> $LOG_FILE
echo "" >> $LOG_FILE

echo "### Backup WordPress files/folder and Database ###" >> $LOG_FILE
echo "" >> $LOG_FILE

echo "$WP_EXPORT" >> $LOG_FILE
$WP_EXPORT >> $LOG_FILE

if ("$COMPRESS" == "tar.gz") then
    echo "cd ../; tar -czf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}" >> $LOG_FILE
    (cd ../; tar -czf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}) >>& $LOG_FILE
else if ("$COMPRESS" == "tar.bz2") then
    echo "cd ../; tar -cjf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}" >> $LOG_FILE
    (cd ../; tar -cjf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}) >>& $LOG_FILE
else if ("$COMPRESS" == "tar.xz") then
    echo "cd ../; tar -cJf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}" >> $LOG_FILE
    (cd ../; tar -cJf ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}) >>& $LOG_FILE
else if ("$COMPRESS" == "zip") then
    echo "cd ../; zip -ry ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}" >> $LOG_FILE
    (cd ../; zip -ry ${backup_dir}/${BACKUP_FILE}  ${WP_NAME}) >>& $LOG_FILE
else
    echo "Invalid compress type."
    goto usage
endif
    
echo "rm -f ${SERVER_USERID}_*.sql" >> $LOG_FILE
rm -f ${SERVER_USERID}_*.sql

if( "$Disable_OBJECT_CACHE" != "" && -d "$WP_DIR/wp-content/plugins/apcu-manager") then
    echo "" >> $LOG_FILE
    ($Disable_OBJECT_CACHE) >>& $LOG_FILE
endif


## 2018-06-08 firstly, core upate (Miya0001-san recommended)
echo "" >> $LOG_FILE
echo "### Core Update ###" >> $LOG_FILE
echo "" >> $LOG_FILE
if ("$LANG_FLAG" == "en") then
  ($WP_CLI core update && $WP_CLI core update-db) >>& $LOG_FILE
else
  ($WP_CLI core update --force --locale=$LANG_FLAG && $WP_CLI core update-db && $WP_CLI core language update) >>& $LOG_FILE
endif


echo "" >> $LOG_FILE
echo "### Plugin Update ###" >> $LOG_FILE
echo "" >> $LOG_FILE
#($WP_CLI plugin list | cut -d '|' -f 2 | awk  '{print "/home/kurs50016/backup/bin/wp plugin update "$1}' | grep -v backwpup | sh) >>& $LOG_FILE
($WP_CLI plugin update --all) >>& $LOG_FILE


echo "" >> $LOG_FILE
echo "### Language Core Update ###" >> $LOG_FILE
echo "" >> $LOG_FILE
($WP_CLI language core update) >>& $LOG_FILE

if( "$Enable_OBJECT_CACHE" != "" && -d "$WP_DIR/wp-content/plugins/apcu-manager") then
    echo "" >> $LOG_FILE
    ($Enable_OBJECT_CACHE) >>& $LOG_FILE

    echo "" >> $LOG_FILE
    ($STATUS_OBJECT_CACHE) >>& $LOG_FILE
endif

echo "" >> $LOG_FILE
echo "End Log at `date +%Y%m%d.%H:%M:%S`" >> $LOG_FILE
echo "" >> $LOG_FILE
echo "$WP_NAME maintenance finished..." >> $LOG_FILE
echo "---" >> $LOG_FILE

end

exit

usage:
 echo "Please check $target_db".
 echo "Usage:"
 echo '[backup folder name]:[WordPress language code]:[Compress Type]:[WordPress folder path]'
 echo 'Compress type: "tar.xz", "tar.bz2","tar.gz","zip" (Default: "tar.gz")'
 exit

 
