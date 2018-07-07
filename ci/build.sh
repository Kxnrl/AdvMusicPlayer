#!/bin/bash

git fetch --unshallow
COUNT=$(git rev-list --count HEAD)
FILE=$COUNT-$2-$3.7z
DATE=$(date +"%Y/%m/%d %H:%M:%S")


#INFO
echo "*** Trigger build ***"


#下载SM
echo "Download sourcemod ..."
wget "http://www.sourcemod.net/latest.php?version=$1&os=linux" -q -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz


#建立include文件夹
mkdir include


#下载Store头文件
echo "Download store.inc ..."
wget "https://github.com/Kxnrl/Store/raw/master/include/store.inc" -q -O include/store.inc


#下载MapMusic头文件
echo "Download mapmusic.inc ..."
wget "https://github.com/Kxnrl/MapMusic-API/raw/master/include/mapmusic.inc" -q -O include/mapmusic.inc


#下载System2头文件
echo "Download system2.inc ..."
wget "https://github.com/dordnung/System2/raw/master/sourcemod/scripting/include/system2.inc" -q -O include/system2.inc
echo "Download system2/request.inc ..."
mkdir include/system2
wget "https://github.com/dordnung/System2/raw/master/sourcemod/scripting/include/system2/request.inc" -q -O include/system2/request.inc
wget "https://github.com/dordnung/System2/raw/master/sourcemod/scripting/include/system2/legacy.inc" -q -O include/system2/legacy.inc


#下载SteamWorks头文件
echo "Download steamworks.inc ..."
if [ "$1" = "1.10" ]; then
    wget "https://github.com/Kxnrl/SteamWorks/raw/master/Pawn/includes/SteamWorks.inc" -q -O include/steamworks.inc
else 
    wget "https://github.com/KyleSanderson/SteamWorks/raw/master/Pawn/includes/SteamWorks.inc" -q -O include/steamworks.inc
fi 


#设置文件为可执行
echo "Set compiler env ..."
chmod +x addons/sourcemod/scripting/spcomp


#更改版本信息
echo "Prepare compile ..."
for file in game/advmusicplayer.sp
do
  sed -i "s%<commit_count>%$COUNT%g" $file > output.txt
  rm output.txt
done


#拷贝文件到编译器文件夹
echo "Copy scripts to compiler folder ..."
cp -rf game/* addons/sourcemod/scripting
cp -rf include/* addons/sourcemod/scripting/include


#建立输出文件夹
echo "Check build folder ..."
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
echo "Move files to build folder ..."
mv include build/scripts
mv game/* build/scripts
mv web/* build/webinterface
mv LICENSE build
mv README.md build


#打包
echo "Compress file ..."
cd build
7z a $FILE -t7z -mx9 LICENSE README.md scripts plugins webinterface >nul


#上传
echo "Upload file RSYNC ..."
RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./$FILE $RSYNC_USER@$RSYNC_HOST::TravisCI/AdvMusicPlayer/$1/

#RAW
if [ "$1" = "1.9" ]; then
    echo "Upload RAW..."
    RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./plugins/advmusicplayer.smx $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/
    RSYNC_PASSWORD=$RSYNC_PSWD rsync -avz --port $RSYNC_PORT ./scripts/com.kxnrl.amp.translations.txt $RSYNC_USER@$RSYNC_HOST::TravisCI/_Raw/translations/
fi
