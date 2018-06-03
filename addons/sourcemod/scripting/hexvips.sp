/*
 * HecVips - HexVips(Core) Plugin.
 * by: Hexer10
 * https://github.com/Hexer10/HexVips
 * 
 * Copyright (C) 2016-2018 Mattia (Hexer10 | Hexah | Papero)
 *
 * This file is part of the HexVips SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */


//Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <autoexecconfig>
#include <hexstocks>
#include <colors>
#include <hexvips>


#undef REQUIRE_PLUGIN
#include <myjailbreak>
#include <lastrequest>
#define REQUIRE_PLUGIN

//Compiler Options
#pragma newdecls required
#pragma semicolon 1


//Defines
#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "<TAG>"
#define DMG_FALL   (1 << 5)

#define VIPMENU 1 //You can remove this without any problems.

//Handle
Handle fOnVipBonusAdded;
Handle fOnVipStatusUpdate;

#if (VIPMENU != 0)
Handle fOnPlayerUseMenu;
#endif

//Int
int iCash = -1;

//Bool
bool bVip[MAXPLAYERS + 1];
bool bIsMYJBAvaible;
bool bIsLRAvaible;
bool bLateLoad;

//Convars bool
ConVar cv_bDisableOnEventday;
ConVar cv_VipJoinMessage;
ConVar cv_bVipTag;
ConVar cv_bVipDefuser;
ConVar cv_bAlwaysBhop;
ConVar cv_bRootAlways;
ConVar cv_bPluginEnable;

//ConVars int
ConVar cv_iVipSpawnHP;
ConVar cv_iVipKillHp;
ConVar cv_iVipKillHpHead;
ConVar cv_iNoFall;
ConVar cv_iCashAmount;

//ConVars float
ConVar cv_fVipSpawnArmour;

//ConVars String
ConVar cv_sVipTag;
ConVar cv_sFlagNeeded;
ConVar cv_sDamageReduction;
ConVar cv_sDamageBoost;


#if (VIPMENU != 0)
#include "vipmenu.sp"
#endif



//Plugin info
public Plugin myinfo = 
{
	name = "hexvips", 
	author = PLUGIN_AUTHOR, 
	description = "Provide bonuses and VipMenu to VIPs", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/Hexer10/VipMenu-HexVips"
};

/********************************************************************************************************************************
                                                              START UP
                                                              
*********************************************************************************************************************************/


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int max_err)
{
	RegPluginLibrary("VipBonus"); //Leave for retro compatibility
	RegPluginLibrary("hexvips");
	
	
	CreateNative("Vip_IsClientVip", Native_CheckVip);
	CreateNative("Vip_SetVipStatus", Native_SetVip);
	
	CreateNative("HexVips_IsClientVip", Native_CheckVip);
	CreateNative("HexVips_SetVipStatus", Native_SetVip);

	fOnVipBonusAdded = CreateGlobalForward("HexVips_OnBonusSet", ET_Event, Param_Cell);
	fOnVipStatusUpdate = CreateGlobalForward("HexVips_VipStatusUpdated", ET_Ignore, Param_Cell, Param_Cell);
	
	#if (VIPMENU != 0)
	CreateNative("Vip_ResetItems", Native_ResetItems);
	
	CreateNative("HexVips_ResetItems", Native_ResetItems);
	fOnPlayerUseMenu = CreateGlobalForward("HexVip_OnPlayerUseMenu", ET_Ignore, Param_Cell, Param_String);
	#endif
	bLateLoad = late;
	return APLRes_Success;
}



public void OnPluginStart()
{
	LoadTranslations("HexVips.phrases");
	LoadTranslations("common.phrases");
	
	//Convars
	CreateConVar("hexvips_version", PLUGIN_VERSION, "HexVips Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_REPLICATED);
	
	if (CreateDirectoryEx("cfg/HexVips"))
		PrintToServer("Created HexVips cfg directory!");
	
	AutoExecConfig_SetFile("Core", "HexVips");
	AutoExecConfig_SetCreateFile(true);
	cv_bPluginEnable = AutoExecConfig_CreateConVar("sm_vipbonus_enable", "1", "1 - Plugin enabled. 0 - Plugin disabled", _, true, 0.0, true, 1.0);
	cv_sFlagNeeded = AutoExecConfig_CreateConVar("vip_core_flag", "a", "Flag to have Vip access ( More flags seprated by a comma, a player need to have at least one of them to get Vip access). - none = No flag needed.");
	cv_VipJoinMessage = AutoExecConfig_CreateConVar("vip_core_join", "1", " 1 - Enable join message. 0 - Disable.");
	cv_sDamageReduction = AutoExecConfig_CreateConVar("vip_core_damage_reduction", "0", " Amount of damage boost ( Can be % also ). 0 - Disable.");
	cv_sDamageBoost = AutoExecConfig_CreateConVar("vip_core_damage_booster", "0", " Amount of damage reduction ( Can be % also ). 0 - Disable.");
	cv_iNoFall = AutoExecConfig_CreateConVar("vip_core_nofall", "100", "Percentage of FallDamage reduction. 0 - Disable.", _, true, 0.0, true, 100.0);
	cv_sVipTag = AutoExecConfig_CreateConVar("vip_core_tag", "[VIP]", "Clan Tag for Vips(Root will never have the tag). - none - Disable.");
	cv_bVipTag = AutoExecConfig_CreateConVar("vip_core_tag_override", "1", " 0 - Place the tag before the exising. 1 - Override the old tag.");
	cv_bVipDefuser = AutoExecConfig_CreateConVar("vip_core_defuser", "1", "Give defuse kit to VIP Cts", _, true, 0.0, true, 1.0);
	cv_iVipSpawnHP = AutoExecConfig_CreateConVar("vip_core_spawn_hp", "70", "+HP on Spawn. 0 - disable", _, true, 0.0, false);
	cv_fVipSpawnArmour = AutoExecConfig_CreateConVar("vip_core_spawn_armour", "100", "+Armour on Spawn. 0 - disabled", 0, true, 0.0, false);
	cv_iVipKillHp = AutoExecConfig_CreateConVar("vip_core_kill_hp", "25", "+HP HP for kills. 0 - disabled", _, true, 0.0, false);
	cv_iVipKillHpHead = AutoExecConfig_CreateConVar("vip_core_kill_hs", "50", "+HP for HS kills. 0 - disabled", _, true, 0.0, false);
	cv_bAlwaysBhop = AutoExecConfig_CreateConVar("vip_core_always_bhop", "1", "1 - Bhop always active. 0 - Should be enable with VipMenu");
	cv_iCashAmount = AutoExecConfig_CreateConVar("vip_core_round_cash", "500", "+Cash every round start. 0 - disabled", _, true, 0.0, true, 30000.00);
	cv_bDisableOnEventday = AutoExecConfig_CreateConVar("vip_core_disable_event", "1", "Disable Vip in MYJB EventDays", _, true, 0.0, true, 1.0);
	cv_bRootAlways = AutoExecConfig_CreateConVar("vip_core_root_default", "1", "1 - Users with root (z) have all VipFeatures. 0 - Must have the VIP flag", _, true, 0.0, true, 1.0);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//OffSet
	iCash = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	//Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_connect", Event_CheckTag);
	HookEvent("player_team", Event_CheckTag);
	HookEvent("player_spawn", Event_CheckTag);
	HookEvent("player_death", Event_CheckTag);
	HookEvent("round_start", Event_CheckTag);
	
	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientPostAdminCheck(i);
		}
	}
	
	#if (VIPMENU != 0)
	OnVipMenuStart();
	#endif
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "myjailbreak"))
	{
		bIsMYJBAvaible = true;
	}
	else if (StrEqual(name, "lastrequest"))
	{
		bIsLRAvaible = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "myjailbreak"))
	{
		bIsMYJBAvaible = false;
	}
	else if (StrEqual(name, "lastrequest"))
	{
		bIsLRAvaible = false;
	}
}

public void OnAllPluginsLoaded()
{
	bIsMYJBAvaible = LibraryExists("myjailbreak");
	bIsLRAvaible = LibraryExists("lastrequest");
}


/********************************************************************************************************************************
                                                              EVENTS
                                                              
*********************************************************************************************************************************/


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientPostAdminCheck(int client)
{
	char sFlagNeeded[16];
	cv_sFlagNeeded.GetString(sFlagNeeded, sizeof(sFlagNeeded));

	if (cv_bRootAlways.BoolValue)
	{
		bVip[client] = CheckAdminFlag(client, sFlagNeeded);
	}
	bVip[client] = CheckAdminFlagEx(client, sFlagNeeded);
	Call_StartForward(fOnVipStatusUpdate);
	Call_PushCell(client);
	Call_PushCell(bVip[client]);
	Call_Finish();
	
	if (!cv_bPluginEnable.BoolValue)
		return;
		
	CheckTag(client);
	if ((bVip[client] && !(GetUserFlagBits(client) & ADMFLAG_ROOT)) && cv_VipJoinMessage.BoolValue)
	{
		char sName[32];
		GetClientName(client, sName, sizeof(sName));
		CPrintToChatAll("%t", "Vip_Joined", sName);
	}
}

public void OnClientDisconnect(int client)
{
	bVip[client] = false;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	char sFlagNeeded[16];
	cv_sFlagNeeded.GetString(sFlagNeeded, sizeof(sFlagNeeded));
	

	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && IsClientAuthorized(i))
	{
		if (cv_bRootAlways.BoolValue)
		{
			bVip[i] = CheckAdminFlag(i, sFlagNeeded);
		}
		bVip[i] = CheckAdminFlagEx(i, sFlagNeeded);
		Call_StartForward(fOnVipStatusUpdate);
		Call_PushCell(i);
		Call_PushCell(bVip[i]);
		Call_Finish();
	}
}

void CheckTag(int client) //HANDLE TAG
{
	char sVipTag[32];
	cv_sVipTag.GetString(sVipTag, sizeof(sVipTag));
	
	if ((IsValidClient(client, false, true) && !StrEqual(sVipTag, "none", false)) && (bVip[client] && !(GetUserFlagBits(client) & ADMFLAG_ROOT)))
	{
		if (cv_bVipTag.BoolValue)
			CS_SetClientClanTag(client, sVipTag);
		else if (!cv_bVipTag.BoolValue)
		{
			char sOldTag[16];
			char sNewTag[32];
			CS_GetClientClanTag(client, sOldTag, sizeof(sOldTag));
			if (StrContains(sOldTag, sVipTag) != -1)
			{
				Format(sNewTag, sizeof(sNewTag), "%s %s", sVipTag, sNewTag);
				CS_SetClientClanTag(client, sNewTag);
			}
		}
	}
	
}

public void Event_CheckTag(Event event, const char[] name, bool dontBroadcast)
{
	if (!cv_bPluginEnable.BoolValue)
		return;
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && HexVips_IsClientVip(i))
	{
		CreateTimer(1.0, DelayCheck, i);
	}
}



/********************************************************************************************************************************
                                                              GENERIC EVENTS
                                                              
*********************************************************************************************************************************/



public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) //Apply Bonuses on spawn
{
	if (!cv_bPluginEnable.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!HexVips_IsClientVip(client))
		return;
	
	OnBonusSet(client);
	
}



public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) //RESET BOOLS ON ROUNDSTART AFTER EVENTDAY
{
	if (!cv_bPluginEnable.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	bIsLR = false;
	
	SetEntData(client, iCash, GetEntData(client, iCash) + cv_iCashAmount.IntValue);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) //HP ON KILL
{
	if (!cv_bPluginEnable.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	
	bool headshot = event.GetBool("headshot");
	if (client == attacker || !IsValidClient(client, true, true) || !IsValidClient(attacker, true, true))
		return;
	
	if (bIsMYJBAvaible && cv_bDisableOnEventday.BoolValue)
		if (MyJailbreak_IsEventDayRunning())
		return;
	
	if (bIsLRAvaible && cv_bDisableLR.BoolValue)
		if (bIsLR)
		return;
	
	if (HexVips_IsClientVip(attacker) && cv_iVipKillHp.IntValue >= 1 && headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHpHead.IntValue + iHealth);
		return;
	}
	else if (HexVips_IsClientVip(attacker) && cv_iVipKillHp.IntValue >= 1 && !headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHp.IntValue + iHealth);
	}
	
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!cv_bPluginEnable.BoolValue)
		return Plugin_Continue;
	
	if (!IsValidClient(attacker, true, false) && (victim == attacker) && !HexVips_IsClientVip(attacker))
		return Plugin_Continue;
	
	if (bIsMYJBAvaible && cv_bDisableOnEventday.BoolValue)
		if (MyJailbreak_IsEventDayRunning())
		return Plugin_Continue;
	
	if (bIsLRAvaible && cv_bDisableLR.BoolValue)
		if (bIsLR)
		return Plugin_Continue;
	
	char sDamageReduction[16];
	char sDamageBoost[16];
	
	cv_sDamageReduction.GetString(sDamageReduction, sizeof(sDamageReduction));
	cv_sDamageBoost.GetString(sDamageBoost, sizeof(sDamageBoost));
	if (IsValidClient(victim, true, false) && cv_sDamageBoost.BoolValue)
	{
		if (StrContains(sDamageBoost, "%", false) != -1)
		{
			ReplaceString(sDamageBoost, sizeof(sDamageBoost), "%", "", false);
			int iDamageBoost = StringToInt(sDamageBoost);
			damage += damage / 100 * iDamageBoost;
			return Plugin_Changed;
		}
		else
		{
			damage += cv_sDamageBoost.IntValue;
			return Plugin_Changed;
		}
	}
	
	if (IsValidClient(victim, true, false) && cv_sDamageReduction.BoolValue)
	{
		if (StrContains(sDamageReduction, "%", false) != -1)
		{
			ReplaceString(sDamageReduction, sizeof(sDamageReduction), "%", "", false);
			int iDamageReduction = StringToInt(sDamageReduction);
			damage -= damage / 100 * iDamageReduction;
			return Plugin_Changed;
		}
		else
		{
			damage -= cv_sDamageReduction.IntValue;
			return Plugin_Changed;
		}
	}
	
	
	return Plugin_Continue;
}


public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!cv_bPluginEnable.BoolValue)
		return Plugin_Continue;
	
	if (HexVips_IsClientVip(victim) && (damagetype & DMG_FALL) && (cv_iNoFall.IntValue >= 1))
	{
		if (cv_iNoFall.IntValue == 100)
			return Plugin_Handled;
		if (cv_iNoFall.IntValue == 0)
			return Plugin_Continue;
		
		damage -= damage / 100 * cv_iNoFall.IntValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons) //DoubleJump & Bhop forked from shanapu!
{
	if (!cv_bPluginEnable.BoolValue)
		return Plugin_Continue;
	
	#if (VIPMENU != 0)
	Menu_OnPlayerRunCmd(client, buttons);
	#endif
	
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	
	if (IsPlayerAlive(client) && cv_bAlwaysBhop.BoolValue && HexVips_IsClientVip(client))
	{
		if (buttons & IN_JUMP)
		{
			if (water <= 1)
			{
				if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
				{
					SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
					if (!(GetEntityFlags(client) & FL_ONGROUND))buttons &= ~IN_JUMP;
				}
			}
		}
	}
	return Plugin_Continue;
}




/********************************************************************************************************************************
                                                              TIMERS
                                                              
*********************************************************************************************************************************/

public Action tDelayLife(Handle timer, any iUserId)
{
	int client = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(client, false, false))
		return Plugin_Continue;
	
	SetEntProp(client, Prop_Send, "m_ArmorValue", cv_fVipSpawnArmour.IntValue);
	int iSpawnHealth = GetClientHealth(client);
	SetEntityHealth(client, iSpawnHealth + cv_iVipSpawnHP.IntValue);
	return Plugin_Continue;
}

public Action DelayCheck(Handle timer, int i)
{
	CheckTag(i);
}


/********************************************************************************************************************************
                                                              STOCKS
                                                              
*********************************************************************************************************************************/

stock bool IsValidTeam(int client, int convar)
{
	if (convar == 3)
	{
		return true;
	}
	else if (GetClientTeam(client) == CS_TEAM_CT && convar == 2)
	{
		return true;
	}
	else if (GetClientTeam(client) == CS_TEAM_T && convar == 1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

/********************************************************************************************************************************
                                                              API
                                                              
*********************************************************************************************************************************/

void OnBonusSet(int client)
{
	Action res = Plugin_Continue;
	
	Call_StartForward(fOnVipBonusAdded);
	Call_PushCell(client);
	Call_Finish(res);
	
	if (res >= Plugin_Handled)
	{
		return;
	}
	
	#if (VIPMENU != 0)
	HexVips_ResetItems(client);
	#endif
	
	if (bIsMYJBAvaible && cv_bDisableOnEventday.BoolValue)
		if (MyJailbreak_IsEventDayRunning())
		return;
	
	if (cv_iVipSpawnHP.IntValue >= 1 || cv_fVipSpawnArmour.IntValue >= 1)
	{
		CreateTimer(3.7, tDelayLife, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); //Delayed timer so this wont be overridden by other plugins
	}
	
	if (cv_bVipDefuser.BoolValue)
	{
		GivePlayerItem(client, "item_defuser");
	}
	return;
}

public int Native_CheckVip(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return bVip[client];
}

public int Native_SetVip(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	bVip[client] = GetNativeCell(2);
	return 1;
}



#if (VIPMENU != 0)
public int Native_ResetItems(Handle plugin, int argc)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	iMenuUse[client] = 0;
	bRegen[client] = false;
	bBhop[client] = false;
	bDoubleJump[client] = false;
	if (hRegenTimer[client] != INVALID_HANDLE)
	{
		hRegenTimer[client].Close();
		hRegenTimer[client] = INVALID_HANDLE;
	}
	return 1;
}
#endif