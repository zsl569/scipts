#!/bin/bash

oracleDir=/home/oracle
backupDate=$(date +%Y-%m-%d)
backupDir=/opt/oracleBackup
deleteDate=$(date -d '15 days ago' +%Y-%m-%d)

oracle_backup(){
	if [[ ! -d $backupDir/$backupDate ]]; then
		mkdir -p $backupDir/$backupDate
	fi

	for file in $(ls $oracleDir | grep .dmp)
	do
		rm -rf $oracleDir/"$file"
	done

	su - oracle -c "expdp info/111111 file=info.dmp log=info.log  compression='all'" &>/dev/null
	if [ $? -ne 0 ];then
		echo "info数据导出失败"
		exit 1
	else
		echo "info数据导出成功"
	fi

	su - oracle -c "expdp spauth/111111 file=spauth.dmp log=spauth.log compression='all'" &>/dev/null
	if [ $? -ne 0 ];then
		echo "spauth数据导出失败"
		exit 1
	else
		echo "spauth数据导出成功"
	fi


  mv $oracleDir/info.* $backupDir/$backupDate
  mv $oracleDir/spauth.* $backupDir/$backupDate
}

upload_oracle_backup_to_fileserver(){
	host=
	passwd=

	cd $backupDir || exit
	zip -r "$backupDate".zip "$backupDate"/
    /usr/bin/expect <<EOF
      set timeout 50000
    	spawn scp $backupDate.zip root@$host:/root/
    	expect {
        	"*yes/no*" {send "yes\r" ; exp_continue}
        	"*password*" {send "$passwd\r" ; exp_continue}
    	}
EOF
	if [ $? -ne 0 ];then
		echo "上传到远程备份服务器失败"
		exit 1
	else
		echo "上传到远程备份服务器成功"
		rm -rf $backupDate.zip
	fi
}

delete_15dAgo_backup(){
	if [[  -d $backupDir/$deleteDate ]]; then

		rm -rf "$backupDir"/"$deleteDate"

		if [ $? -ne 0 ];then
			echo "15天前的Oracle备份删除失败"
			exit 1
		else
			echo "15天前的Oracle备份删除成功"
		fi
	else
		exit 0
	fi
}

oracle_backup

#upload_oracle_backup_to_fileserver

delete_15dAgo_backup
