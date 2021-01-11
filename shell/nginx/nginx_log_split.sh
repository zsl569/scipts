#!/bin/bash

#设置日志文件存放目录
logs_path="/etc/nginx/logs"

#重命名日志文件
mv ${logs_path}/access.log ${logs_path}/access_$(date -d "yesterday" +%Y-%m-%d).log
mv ${logs_path}/error.log ${logs_path}/error_$(date -d "yesterday" +%Y-%m-%d).log

#向nginx主进程发信号重新打开日志
/etc/nginx/sbin/nginx -s reload

#删除7天前的日志
rm -rf ${logs_path}/*_$(date -d "7 days ago" +%Y-%m-%d).log