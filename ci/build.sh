#!/bin/bash

#参数
FTP_HOST=$2
FTP_USER=$3
FTP_PSWD=$4

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$5-$6.7z
DATE=$(date +"%Y/%m/%d %H:%M:%S")


#INFO
echo -e "*** Trigger build ***"


#下载SM
echo -e "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#建立include文件夹
mkdir include


#下载CG头文件
echo -e "Download cg_core.inc ..."
wget "https://github.com/Kxnrl/Core/raw/master/include/cg_core.inc" -q -O include/cg_core.inc


#下载Store头文件
echo -e "Download store.inc ..."
wget "https://github.com/Kxnrl/Store/raw/master/include/store.inc" -q -O include/store.inc


#下载MotdEx头文件
echo -e "Download motdex.inc ..."
wget "https://github.com/Kxnrl/MotdEx/raw/master/include/motdex.inc" -q -O include/motdex.inc


#下载MapMusic头文件
echo -e "Downlaod mapmusic.inc ..."
wget "https://github.com/Kxnrl/MapMusic-API/raw/master/include/mapmusic.inc" -q -O include/mapmusic.inc


#下载System2头文件
echo -e "Download system2.inc ..."
#wget "https://github.com/dordnung/System2/raw/master/system2.inc" -q -O include/system2.inc
wget "https://github.com/dordnung/System2/raw/v2.6/system2.inc" -q -O include/system2.inc


#下载SteamWorks头文件
echo -e "Download steamworks.inc ..."
wget "https://github.com/KyleSanderson/SteamWorks/raw/master/Pawn/includes/SteamWorks.inc" -q -O include/steamworks.inc


#设置文件为可执行
echo -e "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo -e "Prepare compile ..."
for file in game/advmusicplayer.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  sed -i "s%<commit_date>%$DATE%g" $file > output.txt
  rm output.txt
done


#拷贝文件到编译器文件夹
echo -e "Copy scripts to compiler folder ..."
cp -rf game/* addons/sourcemod/scripting
cp -rf include/* addons/sourcemod/scripting/include


#建立输出文件夹
echo -e "Check build folder ..."
mkdir build
mkdir build/scripts
mkdir build/plugins
mkdir build/webinterface


#编译
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/advmusicplayer.sp -o"build/plugins/advmusicplayer.smx"
if [ ! -f "build/plugins/advmusicplayer.smx" ]; then
    echo "Compile failed!"
    exit 1;
fi


#移动文件
echo -e "Move files to build folder ..."
mv include build/scripts
mv game/* build/scripts
mv web/* build/webinterface
mv LICENSE build
mv README.md build


#打包
echo -e "Compress file ..."
cd build
mv scripts/advmusicplayer.sp scripts/advmusicplayer_dontusethis.sp 
7z a $FILE -t7z -mx9 LICENSE README.md scripts plugins webinterface >nul


#上传
echo -e "Upload file ..."
lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /AMP/$5/$1/ $FILE"


#RAW
if [ "$1" = "1.8" ] && [ "$5" = "master" ]; then
    echo "Upload RAW..."
    cd plugins
    lftp -c "open -u $FTP_USER,$FTP_PSWD $FTP_HOST; put -O /AMP/Raw/ advmusicplayer.smx"
fi