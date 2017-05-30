 //Defines
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
#include <myjailbreaknew>
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


//Handle
Handle fOnVipBonusAdded = INVALID_HANDLE;

//Int
int iCash = -1;
int iSprite = -1;
int iObject[MAXPLAYERS + 1] =  { -1, ... };
int iGrabbingDeadBody[MAXPLAYERS + 1] =  { -1, ... };


//fLOAT
float fTime[MAXPLAYERS + 1] =  { -1.0, ... };
float fDistance[MAXPLAYERS + 1] =  { -1.0, ... };

//String
char sFlagNeeded[32];
char sDamageBoost[32];
char sDamageReduction[32];
//Bool
bool bEnablePlugin = false;
bool bIsMYJBAvaible = false;
bool bLateLoad = false;
bool bBlockJump = false;
bool bColored = false;

//Convars bool
ConVar cv_bDisableLR;
ConVar cv_DisableOnEventday;
ConVar cv_VipJoinMessage;
ConVar cv_bVipTag;
ConVar cv_bNoFall;
ConVar cv_bVipDefuser;

//ConVars int
ConVar cv_iVipSpawnHP;
ConVar cv_iVipKillHp;
ConVar cv_iVipKillHpHead;
ConVar cv_iFallReduction;
ConVar cv_iGrab;
ConVar cv_iCashAmount;

//ConVars float
ConVar cv_fVipSpawnArmour;

//ConVars String
ConVar cv_sVipTag;
ConVar cv_sFlagNeeded;
ConVar cv_sDamageReduction;
ConVar cv_sDamageBoost;

//VipMenu Module !!CANNOT REMOVE SAFELY, USE CVARS!!
#include "VipMenu.sp"



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
	CreateNative("IsClientVip", Native_CheckVip);
	fOnVipBonusAdded = CreateGlobalForward("OnVipBonusAssigned", ET_Event, Param_Cell);
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("VipBonus.phrares");
	LoadTranslations("common.phrares");
	LoadTranslations("common.phrares");
	OnVipMenuStart();
	//Convars
	AutoExecConfig_SetFile("VipCore", "VipBonus");
	AutoExecConfig_SetCreateFile(true);
	cv_sFlagNeeded = AutoExecConfig_CreateConVar("vip_core_flag", "a", "Flag to have Vip access. - none = No flag needed.");
	cv_VipJoinMessage = AutoExecConfig_CreateConVar("vip_core_join", "1", " 1 - Enable join message. 0 - Disable.");
	cv_sDamageReduction = AutoExecConfig_CreateConVar("vip_core_damage_reduction", "0", " Amount of damage boost ( Can be % also ). 0 - Disable.");
	cv_sDamageBoost = AutoExecConfig_CreateConVar("vip_core_damage_booster", "0", " Amount of damage reduction ( Can be % also ). 0 - Disable.");
	cv_bNoFall = AutoExecConfig_CreateConVar("vip_core_nofalldamage", "1", " 1 - Enable NoFallDamage. 0 - Disable.");
	cv_iFallReduction = AutoExecConfig_CreateConVar("vip_core_nofallreduction", "100", "% of FallDamage reduction", 0, true, 0.0, true, 100.0);
	cv_sVipTag = AutoExecConfig_CreateConVar("vip_core_tag", "[VIP]", "Clan Tag for Vips. - none - Disable. ( Check phrares: VipJoin message)");
	cv_bVipTag = AutoExecConfig_CreateConVar("vip_core_tag_override", "1", " 0 - Place the tag before the exising. 1 - Override the old tag.");
	cv_bVipDefuser = AutoExecConfig_CreateConVar("vip_core_defuser", "1", "Give defuse kit to VIP Cts", 0, true, 0.0, true, 1.0);
	cv_iGrab = AutoExecConfig_CreateConVar("vip_core_grag", "1", " 2 - Grab anythink. 1 - Grab only dead bodies. 0 - Disable");
	cv_iVipSpawnHP = AutoExecConfig_CreateConVar("vip_core_spawn_hp", "70", "+HP on Spawn. 0 - disable", 0, true, 0.0, false);
	cv_fVipSpawnArmour = AutoExecConfig_CreateConVar("vip_core_spawn_armour", "70", "+Armour on Spawn. 0 - disabled", 0, true, 0.0, false);
	cv_iVipKillHp = AutoExecConfig_CreateConVar("vip_core_kill_hp", "25", "+HP HP for kills. 0 - disabled", 0, true, 0.0, false);
	cv_iVipKillHpHead = AutoExecConfig_CreateConVar("vip_core_kill_hs", "50", "+HP for HS kills. 0 - disabled", 0, true, 0.0, false);
	cv_iCashAmount = AutoExecConfig_CreateConVar("vip_core_round_cash", "500", "+Cash every round start. 0 - disabled", 0, true, 0.0, true, 30000.00);
	cv_bDisableLR = AutoExecConfig_CreateConVar("vip_core_disable_lr", "1", "Disable Vip in sm_hosties LR", 0, true, 0.0, true, 1.0);
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
		for (int i; i <= MaxClients; i++)
		OnClientPutInServer(i);
	}
	
	//Misc
	cv_sFlagNeeded.GetString(sFlagNeeded, sizeof(sFlagNeeded));
	cv_sDamageReduction.GetString(sDamageReduction, sizeof(sDamageReduction));
	cv_sDamageBoost.GetString(sDamageBoost, sizeof(sDamageBoost));
	
}

public void OnMapStart()
{
	iSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
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
	CheckTag(client);
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

void CheckTag(int client) //HANDLE TAG
{
	char sVipTag[32];
	cv_sVipTag.GetString(sVipTag, sizeof(sVipTag));
	if (IsClientVip(client) && !StrEqual(sVipTag, "none", false))
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
	if (IsClientVip(client) && cv_VipJoinMessage.BoolValue)
	{
		CPrintToChatAll("%t", "Vip_Joined", client);
	}
}

public void Event_CheckTag(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, DelayCheck);
}



/********************************************************************************************************************************
                                                              GENERIC EVENTS
                                                              
*********************************************************************************************************************************/



public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) //VIP BONUSES ON SPAWN & RESET VIP BOOLS (MENU USES)
{
	if (!bEnablePlugin)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	AssignVipBonus(client);
}



public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) //RESET BOOLS ON ROUNDSTART AFTER EVENTDAY
{
	EnableVipMenuEDays();
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	SetEntData(client, iCash, cv_iCashAmount.IntValue);
	
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
	if (IsClientVip(client) && client != attacker && cv_iVipKillHp.IntValue >= 1 && headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHpHead.IntValue + iHealth);
		return;
	}
	else if (IsClientVip(attacker) && client != attacker && cv_iVipKillHp.IntValue >= 1 && !headshot)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHp.IntValue + iHealth);
	}
	
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!IsClientVip(attacker))
		return Plugin_Continue;
	
	if (IsValidClient(victim, true, false) && !cv_sDamageBoost.BoolValue)
	{
		if (StrContains(sDamageBoost, "%", false))
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
	
	if (IsValidClient(victim, true, false) && !cv_sDamageReduction.BoolValue)
	{
		if (StrContains(sDamageReduction, "%", false))
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
	
	
	if (damagetype & DMG_FALL && cv_bNoFall.BoolValue)
	{
		if (cv_iFallReduction.FloatValue == 100)
			return Plugin_Handled;
		if (cv_iFallReduction.FloatValue == 0)
			return Plugin_Continue;
		
		damage -= view_as<int>(damage) % cv_iFallReduction.IntValue;
		return Plugin_Changed;
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

public Action DelayCheck(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
	{
		{
			CheckTag(i);
		}
	}
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

Action AssignVipBonus(int client)
{
	Action res = Plugin_Continue;
	
	Call_StartForward(fOnVipBonusAdded);
	Call_PushCell(client);
	Call_Finish(res);
	
	if (res >= Plugin_Handled)
	{
		return Plugin_Handled;
	}
	
	ResetVipBonus(client);
	
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


/********************************************************************************************************************************
                                                              GRABBING MODULE
                                                              
                                           (ALL CREDITS TO BARA, STOLEN FROM HIM & SHANAPU FOR HELP)
                                                              
*********************************************************************************************************************************/



stock void GrabSomething(int client)
{
	
	int ent;
	float VecPos_Ent[3], VecPos_Client[3];
	
	ent = GetObject(client, false);
	
	if (ent == -1)
	{
		return;
	}
	
	ent = EntRefToEntIndex(ent);
	
	if (ent == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_Ent);
	GetClientEyePosition(client, VecPos_Client);
	if (GetVectorDistance(VecPos_Ent, VecPos_Client, false) > 150.0)
	{
		return;
	}
	
	char edictname[128];
	GetEdictClassname(ent, edictname, sizeof(edictname));
	
	if (StrContains(edictname, "prop_", false) == -1 || StrContains(edictname, "door", false) != -1)
	{
		
		iGrabbingDeadBody[client] = false;
		return;
	}
	else
	{
		if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer") || StrEqual(edictname, "func_physbox")) //Client is moving a prop.
		{
			
			if (IsValidEdict(ent) && IsValidEntity(ent))
			{
				ent = ReplacePhysicsEntity(ent);
				iGrabbingDeadBody[client] = false;
				SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
				SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
			}
		}
	}
	
	if (GetEntityMoveType(ent) == MOVETYPE_NONE)
	{
		if (strncmp("player", edictname, 5, false) != 0) //Client is moving a dead body
		{
			iGrabbingDeadBody[client] = true;
			SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
			PrintHintText(client, "Object ist now Unfreezed");
		}
		else
		{
			iGrabbingDeadBody[client] = false;
			SetEntityMoveType(ent, MOVETYPE_WALK);
			return;
		}
	}
	
	
	iObject[client] = EntIndexToEntRef(ent);
	
	fDistance[client] = GetVectorDistance(VecPos_Ent, VecPos_Client, false);
	
	if ((cv_iGrab.IntValue == 1 && iGrabbingDeadBody[client]) || (cv_iGrab.IntValue == 2))
	{
		float position[3];
		TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, position);
	}
	
}




//Stocks
stock void Command_Grab(int client)
{
	GrabSomething(client);
}

stock void Command_UnGrab(int client)
{
	if (ValidGrab(client))
	{
		char edictname[128];
		GetEdictClassname(iObject[client], edictname, 128);
		
		if (StrEqual(edictname, "prop_physics") || StrEqual(edictname, "prop_physics_multiplayer") || StrEqual(edictname, "func_physbox") || StrEqual(edictname, "prop_physics"))
		{
			SetEntPropEnt(iObject[client], Prop_Data, "m_hPhysicsAttacker", 0);
		}
	}
	
	iObject[client] = -1;
	fTime[client] = 0.0;
}


stock bool ValidGrab(int client)
{
	int obj = iObject[client];
	if (obj != -1 && IsValidEntity(obj) && IsValidEdict(obj))
	{
		return (true);
	}
	return (false);
}
stock int GetObject(int client, bool hitSelf = true)
{
	int ent = -1;
	
	if (IsClientInGame(client))
	{
		if (ValidGrab(client))
		{
			ent = EntRefToEntIndex(iObject[client]);
			return (ent);
		}
		
		ent = TraceToEntity(client);
		
		if (IsValidEntity(ent) && IsValidEdict(ent))
		{
			char edictname[64];
			GetEdictClassname(ent, edictname, 64);
			if (StrEqual(edictname, "worldspawn"))
			{
				if (hitSelf)
				{
					ent = client;
				}
				else
				{
					ent = -1;
				}
			}
		}
		else
		{
			ent = -1;
		}
	}
	
	return (ent);
}

public int TraceToEntity(int client)
{
	float vecClientEyePos[3], vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);
	
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceASDF, client);
	
	if (TR_DidHit(null))
	{
		return (TR_GetEntityIndex(null));
	}
	
	return (-1);
}

public bool TraceASDF(int entity, int mask, any data)
{
	return (data != entity);
}

stock int ReplacePhysicsEntity(int ent)
{
	float VecPos_Ent[3], VecAng_Ent[3];
	
	char model[128];
	GetEntPropString(ent, Prop_Data, "m_ModelName", model, 128);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecPos_Ent);
	GetEntPropVector(ent, Prop_Send, "m_angRotation", VecAng_Ent);
	AcceptEntityInput(ent, "Wake");
	AcceptEntityInput(ent, "EnableMotion");
	AcceptEntityInput(ent, "EnableDamageForces");
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	
	TeleportEntity(ent, VecPos_Ent, VecAng_Ent, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	
	return (ent);
}



public Action Adjust(Handle timer)
{
	
	float vecDir[3];
	float vecPos[3];
	float vecPos2[3];
	float vecVel[3];
	float viewang[3];
	
	for (int i = 1; i <= MaxClients; i++)if (IsPlayerAlive(i))
	{
		if (ValidGrab(i))
		{
			GetClientEyeAngles(i, viewang);
			GetAngleVectors(viewang, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(i, vecPos);
			
			int color[4];
			
			if (bColored)
			{
				if (fTime[i] == 0.0 || GetGameTime() < fTime[i])
				{
					color[0] = GetRandomInt(0, 255);
					color[1] = GetRandomInt(0, 255);
					color[2] = GetRandomInt(0, 255);
					color[3] = 255;
				}
			}
			else
			{
				color[0] = 255;
				color[1] = 0;
				color[2] = 0;
				color[3] = 255;
			}
			
			vecPos2 = vecPos;
			vecPos[0] += vecDir[0] * fDistance[i];
			vecPos[1] += vecDir[1] * fDistance[i];
			vecPos[2] += vecDir[2] * fDistance[i];
			
			GetEntPropVector(iObject[i], Prop_Send, "m_vecOrigin", vecDir);
			
			TE_SetupBeamPoints(vecPos2, vecDir, iSprite, 0, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, color, 0);
			TE_SendToAll();
			
			fTime[i] = GetGameTime() + 1.0;
			
			SubtractVectors(vecPos, vecDir, vecVel);
			ScaleVector(vecVel, 10.0);
			
			TeleportEntity(iObject[i], NULL_VECTOR, NULL_VECTOR, vecVel);
		}
	}
}

public void OnClientDisconnect(int client)
{
	iObject[client] = -1;
	fTime[client] = 0.0;
}



public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	Menu_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
	
	if (cv_iGrab.IntValue == 0)
		return Plugin_Continue;
	
	if (buttons & IN_JUMP)
	{
		if (bBlockJump)
		{
			int iEnt = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
			
			if (iEnt > 0)
			{
				char sName[128];
				GetEdictClassname(iEnt, sName, sizeof(sName));
				
				if (StrContains(sName, "prop_", false) == -1 || StrContains(sName, "door", false) != -1)
				{
					return Plugin_Continue;
				}
				else
				{
					if (StrEqual(sName, "prop_physics") || StrEqual(sName, "prop_physics_multiplayer") || StrEqual(sName, "func_physbox") || StrEqual(sName, "prop_physics"))
					{
						if (IsValidEdict(iEnt) && IsValidEntity(iEnt))
						{
							buttons &= ~IN_JUMP;
							return Plugin_Changed;
						}
					}
				}
			}
		}
	}
	
	if (buttons & IN_USE)
	{
		if (IsPlayerAlive(client) && !ValidGrab(client))
		{
			Command_Grab(client);
		}
	}
	else if (ValidGrab(client))
	{
		Command_UnGrab(client);
	}
	
	return Plugin_Continue;
}
