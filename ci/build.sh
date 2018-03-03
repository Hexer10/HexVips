#!/bin/bash
set -ev

TAG=$1

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=1.8&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugins version"
for file in addons/sourcemod/scripting/VipBonus.sp
do
  sed -i "s/<TAG>/$TAG/g" $file > output.txt
  rm output.txt
done

addons/sourcemod/scripting/compile.sh VipBonus.sp

echo "Create clean plugins folder"
mkdir -p build/addons/sourcemod/scripting/include
mkdir build/addons/sourcemod/plugins
mkdir build/addons/sourcemod/translations

echo "Move Phrases"
mv addons/sourcemod/translations/* build/addons/sourcemod/translations

echo "Move plugins files to their folder"
mv addons/sourcemod/scripting/include/vipbonus.inc build/addons/sourcemod/scripting/include
mv addons/sourcemod/scripting/VipBonus.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/VipMenu.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/compiled/VipBonus.smx build/addons/sourcemod/plugins

echo "Compress the plugin"
mv LICENSE build/
cd build/ && zip -9rq VipBonus.zip addons/ LICENSE && mv VipBonus.zip ../

cd ..
ls build/addons/sourcemod/translations
ls build/addons/sourcemod


echo "Build done"