#!/bin/bash

#nginx安装目录
nginx_path=/etc/nginx
#配置nginx命令
nginx=$nginx_path/sbin/nginx
#获取当前安装的版本
localVersion=$($nginx -V 2>&1 | sed -n 1p | cut -d'/' -f2-)
#获取需要安装的版本
upgradeVersion=$1


#下载nginx源码包失败继续下载的方法
function down_file()
{
    local count=0
    while true ; do
        sleep 3
        wget https://nginx.org/download/nginx-$upgradeVersion.tar.gz  &>/dev/null
        if [ $? == 0 ] ; then
            echo ">>>>>文件下载成功"
            break;
        else
            (( count = ${count} + 1 ))
            echo ">>>>>文件下载失败，正在重新下载"
            rm -rf nginx-"$upgradeVersion".tar.gz
        fi
    done
}

#判断是否输入需要更新的版本
if [ -z "$upgradeVersion" ]; then
echo ">>>>>请输入要更新的版本"
exit 0
fi

#判断版本是否需要更新
if [ "$localVersion" == "$upgradeVersion" ]; then
echo ">>>>>无需更新，当前安装版本即$localVersion"
exit 0
fi

#下载需要更新的版本
echo "当前安装版本为：$localVersion,更新版本为：$upgradeVersion"
echo ">>>>>下载新版nginx源码包"
down_file


echo ">>>>>停止nginx服务"
$nginx -s stop


echo ">>>>>备份nginx目录"
cp -r $nginx_path /etc/nginx_"$localVersion"

echo ">>>>>安装所需依赖"
yum -y install make zlib zlib-devel gcc-c++ libtool openssl openssl-devel  &>/dev/null

echo ">>>>>解压源码包"
tar -xzvf nginx-"$upgradeVersion".tar.gz  &>/dev/null
cd nginx-"$upgradeVersion" || exit

echo ">>>>>编译安装nginx"
#./configure `nginx -V 2>&1 | sed -n 5p | cut -d':' -f2-`
./configure --prefix=$nginx_path --with-http_stub_status_module --with-http_ssl_module  --with-stream  &>/dev/null
make &>/dev/null
make install  &>/dev/null

echo ">>>>>启动nginx服务"
$nginx

echo ">>>>>删除源码包"
cd ..
rm -rf nginx-"$upgradeVersion".tar.gz
rm -rf nginx-"$upgradeVersion"

echo ">>>>>版本更新完成"