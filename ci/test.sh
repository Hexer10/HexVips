#!/bin/bash
set -ev

echo "Download und extract sourcemod"
wget -q "http://www.sourcemod.net/latest.php?version=$VERSION&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Compile VipBonus plugin"
addons/sourcemod/scripting/spcomp -E -v0 addons/sourcemod/scripting/VipBonus.sp