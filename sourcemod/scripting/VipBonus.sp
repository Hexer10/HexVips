/*
 * VipMenu-Bonuses - VipBonus(Core) Plugin.
 * by: Hexer10
 * https://github.com/Hexer10/VipMenu-Bonuses
 * 
 * Copyright (C) 2016-2017 Mattia (Hexer10 | Hexah | Papero)
 *
 * This file is part of the VipMenu-Bonuses SourceMod Plugin.
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
#include <VipBonus>

//#include <chat-processor>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#include <myjailbreak>
#include <lastrequest>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
//Compiler Options
#pragma newdecls required
#pragma semicolon 1
//Defines



#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VER "2.00"
#define DMG_FALL   (1 << 5)

#define VIPMENU 1 //You can remove this without any problems.

//Handle
Handle fOnVipBonusAdded = INVALID_HANDLE;

#if (VIPMENU != 0)
Handle fOnPlayerUseMenu;
#endif

//Int
int iCash = -1;

//String
char sFlagNeeded[32];
char sDamageBoost[32];
char sDamageReduction[32];

//Bool
bool bEnablePlugin = false;
bool bIsMYJBAvaible = false;
bool bLateLoad = false;

//Convars bool
ConVar cv_DisableOnEventday;
ConVar cv_VipJoinMessage;
ConVar cv_bVipTag;
ConVar cv_bVipDefuser;
ConVar cv_bAlwaysBhop;

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
#include "VipMenu.sp"
#endif



//Plugin info
public Plugin myinfo = 
{
	name = "VipBonus", 
	author = PLUGIN_AUTHOR, 
	description = "Provide some bonuses and VipMenu to VIPs", 
	version = PLUGIN_VER, 
	url = "https://github.com/Hexer10/VipMenu-Bonuses"
};

/********************************************************************************************************************************
                                                              START UP
                                                              
*********************************************************************************************************************************/


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int max_err)
{
	RegPluginLibrary("vipbonus");
	CreateNative("Vip_IsClientVip", Native_CheckVip);
	fOnVipBonusAdded = CreateGlobalForward("Vip_OnBonusSet", ET_Event, Param_Cell);
	//	fOnVipMenuOpened = CreateGlobalForward("OnVipMEnuOpen", ET_Event, Param_Cell);
	#if (VIPMENU != 0)
	fOnPlayerUseMenu = CreateGlobalForward("Vip_OnPlayerUseMenu", ET_Ignore, Param_Cell, Param_String);
	Menu_AskPluginLoad2();
	#endif
	bLateLoad = late;
	return APLRes_Success;
}


public void OnPluginStart()
{
	LoadTranslations("VipBonus.phrases");
	LoadTranslations("common.phrases");
	//Convars
	AutoExecConfig_SetFile("VipCore", "VipBonus");
	AutoExecConfig_SetCreateFile(true);
	cv_sFlagNeeded = AutoExecConfig_CreateConVar("vip_core_flag", "a", "Flag to have Vip access ( More flags seprated by a comma, a player need to have at least one of them to get Vip access). - none = No flag needed.");
	cv_VipJoinMessage = AutoExecConfig_CreateConVar("vip_core_join", "1", " 1 - Enable join message. 0 - Disable.");
	cv_sDamageReduction = AutoExecConfig_CreateConVar("vip_core_damage_reduction", "0", " Amount of damage boost ( Can be % also ). 0 - Disable.");
	cv_sDamageBoost = AutoExecConfig_CreateConVar("vip_core_damage_booster", "0", " Amount of damage reduction ( Can be % also ). 0 - Disable.");
	cv_iNoFall = AutoExecConfig_CreateConVar("vip_core_nofall", "100", "% of FallDamage reduction. 0 - Disable.", 0, true, 0.0, true, 100.0);
	cv_sVipTag = AutoExecConfig_CreateConVar("vip_core_tag", "[VIP]", "Clan Tag for Vips. - none - Disable. ( Check phrares: VipTag message)");
	cv_bVipTag = AutoExecConfig_CreateConVar("vip_core_tag_override", "1", " 0 - Place the tag before the exising. 1 - Override the old tag.");
	cv_bVipDefuser = AutoExecConfig_CreateConVar("vip_core_defuser", "1", "Give defuse kit to VIP Cts", 0, true, 0.0, true, 1.0);
	//	cv_iGrab = AutoExecConfig_CreateConVar("vip_core_grag", "1", " 2 - Grab anythink. 1 - Grab only dead bodies. 0 - Disable. ( WIP )");
	cv_iVipSpawnHP = AutoExecConfig_CreateConVar("vip_core_spawn_hp", "70", "+HP on Spawn. 0 - disable", 0, true, 0.0, false);
	cv_fVipSpawnArmour = AutoExecConfig_CreateConVar("vip_core_spawn_armour", "70", "+Armour on Spawn. 0 - disabled", 0, true, 0.0, false);
	cv_iVipKillHp = AutoExecConfig_CreateConVar("vip_core_kill_hp", "25", "+HP HP for kills. 0 - disabled", 0, true, 0.0, false);
	cv_iVipKillHpHead = AutoExecConfig_CreateConVar("vip_core_kill_hs", "50", "+HP for HS kills. 0 - disabled", 0, true, 0.0, false);
	cv_bAlwaysBhop = AutoExecConfig_CreateConVar("vip_core_always_bhop", "1", "1 - Bhop always active. 0 - Should be enable with VipMenu");
	cv_iCashAmount = AutoExecConfig_CreateConVar("vip_core_round_cash", "500", "+Cash every round start. 0 - disabled", 0, true, 0.0, true, 30000.00);
	cv_DisableOnEventday = AutoExecConfig_CreateConVar("vip_core_disable_event", "1", "Disable Vip in MYJB EventDays", 0, true, 0.0, true, 1.0);
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
			OnClientPutInServer(i);
	}
	
	//Misc
	cv_sFlagNeeded.GetString(sFlagNeeded, sizeof(sFlagNeeded));
	cv_sDamageReduction.GetString(sDamageReduction, sizeof(sDamageReduction));
	cv_sDamageBoost.GetString(sDamageBoost, sizeof(sDamageBoost));
	
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
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "myjailbreak"))
	{
		bIsMYJBAvaible = false;
	}
}

public void OnAllPluginsLoaded()
{
	bIsMYJBAvaible = LibraryExists("myjailbreak");
}


/********************************************************************************************************************************
                                                              EVENTS
                                                              
*********************************************************************************************************************************/


public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void CheckTag(int client) //HANDLE TAG
{
	char sVipTag[32];
	cv_sVipTag.GetString(sVipTag, sizeof(sVipTag));
	if (Vip_IsClientVip(client) && !StrEqual(sVipTag, "none", false) && !CheckCommandAccess(client, "root_tag_access", ADMFLAG_ROOT, true))
	{
		if (cv_bVipTag.BoolValue)
			CS_SetClientClanTag(client, sVipTag);
		else if (!cv_bVipTag.BoolValue)
		{
			char sOldTag[16];
			char sNewTag[32];
			CS_GetClientClanTag(client, sOldTag, sizeof(sOldTag));
			if (StrContains(sOldTag, sVipTag) != -1)
				Format(sNewTag, sizeof(sNewTag), "%s %s", sVipTag, sNewTag);
		}
	}
	
}

public void OnClientPostAdminCheck(int client)
{
	CheckTag(client);
	if (Vip_IsClientVip(client) && cv_VipJoinMessage.BoolValue)
	{
		CPrintToChatAll("%t", "Vip_Joined", client);
	}
}

public void Event_CheckTag(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i, false, true) && Vip_IsClientVip(i) && !CheckCommandAccess(i, "vip_allow_admin_tag", ADMFLAG_ROOT, true))
	{
		CreateTimer(1.0, DelayCheck, i);
	}
}



/********************************************************************************************************************************
                                                              GENERIC EVENTS
                                                              
*********************************************************************************************************************************/



public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) //VIP BONUSES ON SPAWN & RESET VIP BOOLS (MENU USES)
{
	
	if (!bEnablePlugin)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	
	OnBonusSet(client);
	
}



public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) //RESET BOOLS ON ROUNDSTART AFTER EVENTDAY
{
	#if (VIPMENU != 0)
	EnableVipMenuEDays();
	#endif
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	SetEntData(client, iCash, GetEntData(client, iCash) + cv_iCashAmount.IntValue);
	
	if (bEnablePlugin)
	{
		bEnablePlugin = false;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) //HP ON KILL
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	
	bool headshot = event.GetBool("headshot");
	if (client == attacker || !IsValidClient(client, true, true) || !IsValidClient(attacker, true, true) || (cv_DisableOnEventday.BoolValue && MyJailbreak_IsEventDayRunning()))
	{
		return;
	}
	if (Vip_IsClientVip(attacker) && cv_iVipKillHp.IntValue >= 1 && headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHpHead.IntValue + iHealth);
		return;
	}
	else if (Vip_IsClientVip(attacker) && cv_iVipKillHp.IntValue >= 1 && !headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHp.IntValue + iHealth);
	}
	
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!IsValidClient(attacker, true, false) && (victim == attacker) && !Vip_IsClientVip(attacker) || (cv_DisableOnEventday.BoolValue && MyJailbreak_IsEventDayRunning()))
		return Plugin_Continue;
	
	if (IsValidClient(victim, true, false) && cv_sDamageBoost.BoolValue)
	{
		if (StrContains(sDamageBoost, "%", false) != -1)
		{
			ReplaceString(sDamageBoost, sizeof(sDamageBoost), "%", "", false);
			int iDamageBoost = StringToInt(sDamageBoost);
			damage += view_as<int>(damage) % iDamageBoost;
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
			damage -= view_as<int>(damage) % iDamageReduction;
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
	if (Vip_IsClientVip(victim) && (damagetype & DMG_FALL) && (cv_iNoFall.IntValue >= 1))
	{
		if (cv_iNoFall.IntValue == 100)
			return Plugin_Handled;
		if (cv_iNoFall.IntValue == 0)
			return Plugin_Continue;
		
		damage -= view_as<int>(damage) % cv_iNoFall.IntValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons) //DoubleJump & Bhop forked from shanapu!
{
	#if (VIPMENU != 0)
	Menu_OnPlayerRunCmd(client, buttons);
	#endif
	
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	
	if (IsPlayerAlive(client) && cv_bAlwaysBhop.BoolValue && Vip_IsClientVip(client))
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

public Action tDelayLife(Handle timer, any client)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", cv_fVipSpawnArmour.IntValue);
	int i_SpawnHealth = GetClientHealth(client);
	SetEntityHealth(client, i_SpawnHealth + cv_iVipSpawnHP.IntValue);
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

Action OnBonusSet(int client)
{
	Action res = Plugin_Continue;
	
	Call_StartForward(fOnVipBonusAdded);
	Call_PushCell(client);
	Call_Finish(res);
	
	if (res >= Plugin_Handled)
	{
		return Plugin_Handled;
	}
	
	#if (VIPMENU != 0)
	Vip_ResetItems(client);
	#endif
	
	if (bIsMYJBAvaible && cv_DisableOnEventday.BoolValue)
	{
		return Plugin_Handled;
	}
	
	if (cv_iVipSpawnHP.IntValue >= 1 || cv_fVipSpawnArmour.IntValue >= 1)
	{
		CreateTimer(3.7, tDelayLife, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (cv_bVipDefuser.BoolValue)
	{
		GivePlayerItem(client, "item_defuser");
	}
	return Plugin_Continue;
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
	return CheckAdminFlag(client, sFlagNeeded);
}



#if (VIPMENU != 0)
Action Vip_OnMenuCreated(int client, const char[] item)
{
	
}

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
	delete hRegenTimer[client];
	return 1;
}
#endif
