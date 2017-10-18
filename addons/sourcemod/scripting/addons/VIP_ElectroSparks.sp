#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <vipbonus>
#include <hexstocks>



#pragma semicolon 1
#pragma newdecls required




#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"


public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = "csitajb.it"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath);
}



public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (attacker != client && Vip_IsClientVip(attacker))
	{
		float vPos[3];
		GetClientAbsOrigin(client, vPos);
		Func_Tesla(vPos);
	}
}

void Func_Tesla(const float vPos[3])
{
	int iEnt = CreateEntityByName("point_tesla");
	DispatchKeyValue(iEnt, "beamcount_min", "5");
	DispatchKeyValue(iEnt, "beamcount_max", "10");
	DispatchKeyValue(iEnt, "lifetime_min", "0.2");
	DispatchKeyValue(iEnt, "lifetime_max", "0.5");
	DispatchKeyValue(iEnt, "m_flRadius", "75.0");
	DispatchKeyValue(iEnt, "m_SoundName", "DoSpark");
	DispatchKeyValue(iEnt, "texture", "sprites/physbeam.vmt");
	DispatchKeyValue(iEnt, "m_Color", "255 255 255");
	DispatchKeyValue(iEnt, "thick_min", "1.0");
	DispatchKeyValue(iEnt, "thick_max", "10.0");
	DispatchKeyValue(iEnt, "interval_min", "0.1");
	DispatchKeyValue(iEnt, "interval_max", "0.2");
	
	DispatchSpawn(iEnt);
	TeleportEntity(iEnt, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEnt, "TurnOn");
	AcceptEntityInput(iEnt, "DoSpark");
	
	SetVariantString("OnUser1 !self:kill::2.0:-1");
	AcceptEntityInput(iEnt, "AddOutput");
	AcceptEntityInput(iEnt, "FireUser1");
}




