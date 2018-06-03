#!/bin/bash
set -ev

TAG=$1

echo "Create clean plugins folder"
mkdir -p build/addons/sourcemod/scripting/include
mkdir -p build/addons/sourcemod/plugins
mkdir -p build/addons/sourcemod/translations

#Move firstly the Phrases
echo "Move Phrases"
mv addons/sourcemod/translations/* build/addons/sourcemod/translations/

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=1.8&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugins version"
for file in addons/sourcemod/scripting/hexvips.sp
do
  sed -i "s/<TAG>/$TAG/g" $file > output.txt
  rm output.txt
done

addons/sourcemod/scripting/compile.sh hexvips.sp

echo "Move plugins files to their folder"
mv addons/sourcemod/scripting/include/hexvips.inc build/addons/sourcemod/scripting/include
mv addons/sourcemod/scripting/hexvips.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/vipmenu.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/compiled/hexvips.smx build/addons/sourcemod/plugins

echo "Compress the plugin"
mv LICENSE build/
cd build/ && zip -9rq HexVips.zip addons/ LICENSE && mv HexVips.zip ../

cd ..
ls build/addons/sourcemod/translations
ls build/addons/sourcemod


echo "Build done"