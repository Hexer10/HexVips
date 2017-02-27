 //Defines
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexecconfig>
#include <hexstocks>
#include <colors>
//#include <chat-processor>

#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <myjailbreaknew>
#tryinclude <lastrequest>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN
//Compiler Options
#pragma newdecls required
#pragma semicolon 1
//Defines
#define Life "#life"
#define Armour "#armour"
#define Nade "#nade"
#define Smoke "#smoke"
#define Speed "#speed"
#define Gravity "#gravity"
#define Regen "#regen"
#define Bhop "#bhop"
#define Weap "#weap"

#define DEBUG

#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VER "1.00"


//Chars
char sFlagNeeded[32];
char sWeapon[32];
char sMenuName[32];
//Bools
bool bRegen[MAXPLAYERS + 1] = false;
bool bBhop[MAXPLAYERS + 1] = false;
bool bDoubleJump[MAXPLAYERS + 1] = false;
bool bEnablePlugin = false;
bool bIsMYJBAvaible = false;
//Handle
Handle h_Regen[MAXPLAYERS + 1];
//Int
int iMenuUse[MAXPLAYERS + 1];
int iDJumped[MAXPLAYERS + 1];
//Convars bool
ConVar cv_bEnableVipMenu;
ConVar cv_bMenuLife;
ConVar cv_bMenuGravity;
ConVar cv_bMenuArmour;
ConVar cv_bMenuRegen;
ConVar cv_bMenuSpeed;
ConVar cv_bMenuNade;
ConVar cv_bMenuSmoke;
ConVar cv_bMenuBhop;
ConVar cv_bMenuDobleJump;
ConVar cv_bStopTimer;
ConVar cv_bDisableLR;
ConVar cv_DisableOnEventday;
ConVar cv_VipJoinMessage;
//ConVars int
ConVar cv_iVipSpawnHP;
ConVar cv_iRegenMaxHP;
ConVar cv_iRegenHP;
ConVar cv_iLifeHP;
ConVar cv_iArmour;
ConVar cv_iVipKillHp;
ConVar cv_iMenuUse;
//ConVars float
ConVar cv_fVipSpawnArmour;
ConVar cv_fHpTimer;
ConVar cv_fSpeed;
ConVar cv_fGravity;

ConVar cv_sFlagNeeded;
ConVar cv_sWeapon;
ConVar cv_sVipTag;
//Plugin info
public Plugin myinfo = 
{
	name = "VipBonus", 
	author = PLUGIN_AUTHOR, 
	description = "Provide some bonuses and VipMenu to VIPs", 
	version = PLUGIN_VER, 
	url = "sourcemod.net"
};


//Start
public void OnPluginStart()
{
	LoadTranslations("VipBonus.phrares");
	//Convars
	AutoExecConfig_SetFile("VipBonus");
	AutoExecConfig_SetCreateFile(true);
	cv_sFlagNeeded = AutoExecConfig_CreateConVar("sm_VipFlag", "a", "Flag needed to be VIP");
	cv_VipJoinMessage = AutoExecConfig_CreateConVar("sm_VipJoinMessage", "1", "Enable join messages");
	cv_sVipTag = AutoExecConfig_CreateConVar("sm_VipTag", "[VIP]", "Clan Tag for Vips, none = disabled");
	cv_iVipSpawnHP = AutoExecConfig_CreateConVar("sm_VipSpawnHP", "70", "+HP on Spawn, 0 = disabled", 0, true, 0.0, false);
	cv_fVipSpawnArmour = AutoExecConfig_CreateConVar("sm_VipSpawnArmour", "70", "+Armour on Spawn, 0 = disabled", 0, true, 0.0, false);
	cv_iVipKillHp = AutoExecConfig_CreateConVar("sm_VipKillHP", "25", "+HP HP for kills, 0 = disabled", 0, true, 0.0, false);
	//cv_iVipKillHp = AutoExecConfig_CreateConVar("sm_VipKillHeadHP", "50", "How much +HP should have Vips for head kills, 0 = disabled", 0, true, 0.0, false); //WorkInProgress
	cv_bEnableVipMenu = AutoExecConfig_CreateConVar("sm_VipMenu", "1", "Enable VipMenu?", 0, true, 0.0, true, 1.0);
	cv_iMenuUse = AutoExecConfig_CreateConVar("sm_VipMenuUse", "1", "Max VipMenu times", 0, true, 0.0, true, 1.0); //WorkInProgress
	cv_bMenuLife = AutoExecConfig_CreateConVar("sm_MenuLife", "1", "Enable Life > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuArmour = AutoExecConfig_CreateConVar("sm_MenuArmour", "1", "Enable Armour > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuGravity = AutoExecConfig_CreateConVar("sm_MenuGravity", "1", "Enable Gravity > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuSpeed = AutoExecConfig_CreateConVar("sm_MenuSpeed", "1", "Enable Speed > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuNade = AutoExecConfig_CreateConVar("sm_MenuNade", "1", "Enable HE Nade > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuSmoke = AutoExecConfig_CreateConVar("sm_MenuSmoke", "1", "Enable Smoke > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuRegen = AutoExecConfig_CreateConVar("sm_MenuRegen", "1", "Enable Regen > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuBhop = AutoExecConfig_CreateConVar("sm_MenuBhop", "1", "Enable BunnyHop > VipMenu", 0, true, 0.0, true, 1.0);
	cv_bMenuDobleJump = AutoExecConfig_CreateConVar("sm_MenuDoubleJump", "1", "Enable DoubleJump > VipMenu", 0, true, 0.0, true, 1.0);
	cv_sWeapon = AutoExecConfig_CreateConVar("sm_MenuWeapon", "glock", "CustomWeapon > VipMenu, none = disabled");
	cv_iLifeHP = AutoExecConfig_CreateConVar("sm_BLifeHP", "50", "Quantity of +HP");
	cv_iArmour = AutoExecConfig_CreateConVar("sm_BArmour", "50", "Quantity of +Armour");
	cv_fGravity = AutoExecConfig_CreateConVar("sm_BGravity", "0.5", "Quantity of Gravity");
	cv_fSpeed = AutoExecConfig_CreateConVar("sm_BSpeed", "1.5", "Quantity of Speed");
	cv_iRegenMaxHP = AutoExecConfig_CreateConVar("sm_RegenMaxHP", "200", "Max HP to reach > Regen");
	cv_fHpTimer = AutoExecConfig_CreateConVar("sm_RegenInt", "1.0", "Regen interval");
	cv_iRegenHP = AutoExecConfig_CreateConVar("sm_HpRegen", "10", "+HP for Regen");
	cv_bStopTimer = AutoExecConfig_CreateConVar("sm_RegenStop", "0", "Stop Regen when reached the MaxHP (0) or continue when get lower (1)?", 0, true, 0.0, true, 1.0);
	cv_bDisableLR = AutoExecConfig_CreateConVar("sm_DisableVipLR", "1", "Disable VipMenu > LR", 0, true, 0.0, true, 1.0);
	cv_DisableOnEventday = AutoExecConfig_CreateConVar("sm_DisableVipEvent", "1", "Disable VipMenu > MYJB EventDay", 0, true, 0.0, true, 1.0);
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	//Commands
	RegConsoleCmd("sm_vipmenu", Command_VipMenu, "Open VipMenu for VIPs");
	RegAdminCmd("sm_resetvipmenu", Command_ResMenu, ADMFLAG_CONFIG, "Reset VIPMenu advantages (Weapons remains)");
	//Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_connect", Event_CheckTag);
	HookEvent("player_team", Event_CheckTag);
	HookEvent("player_spawn", Event_CheckTag);
	HookEvent("player_death", Event_CheckTag);
	HookEvent("round_start", Event_CheckTag);
	//Misc
	cv_sFlagNeeded.GetString(sFlagNeeded, sizeof(sFlagNeeded));
	cv_sWeapon.GetString(sWeapon, sizeof(sWeapon));
	
}
/********************************************************************************************************************************
                                                              COMMANDS
                                                              
*********************************************************************************************************************************/



public Action Command_ResMenu(int client, int args)
{
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg1, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_ALIVE, /* Only allow alive players */
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
	}
	for (int i = 0; i < target_count; i++)
	{
		iMenuUse[target_list[i]] = 0;
		bRegen[target_list[i]] = false;
		bBhop[target_list[i]] = false;
		bDoubleJump[target_list[i]] = false;
		if (h_Regen[client] != INVALID_HANDLE)
		{
			KillTimer(h_Regen[client]);
			h_Regen[client] = INVALID_HANDLE;
		}
	}
	return Plugin_Handled;
}

public Action Command_VipMenu(int client, int args)
{
	if (!CheckAdminFlag(client, sFlagNeeded))
	{
		CReplyToCommand(client, "%t %t", "%t", "Prefix", "Not_Vip");
	}
	if (!cv_bEnableVipMenu.BoolValue)
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Plugin_Disable");
	}
	else if (!IsPlayerAlive(client)) //Alive check
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Player_Death");
	}
	else if (iMenuUse[client] == cv_iMenuUse.IntValue)
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Menu_Already");
	}
	else //Client is valid
	{
		vmenu(client);
	}
	
	return Plugin_Handled;
}

/********************************************************************************************************************************
                                                              EVENTS
                                                              
*********************************************************************************************************************************/


public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) //VIP BONUSES ON SPAWN & RESET VIP BOOLS (MENU USES)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	iMenuUse[client] = 0;
	bRegen[client] = false;
	bBhop[client] = false;
	if (h_Regen[client] != INVALID_HANDLE)
	{
		KillTimer(h_Regen[client]);
		h_Regen[client] = INVALID_HANDLE;
	}
	
	if (CheckAdminFlag(client, sFlagNeeded)) //Perm check
	{
		if (cv_DisableOnEventday)
		{
			if (bIsMYJBAvaible && MyJailbreak_IsEventDayRunning())
			{
				bEnablePlugin = true;
				cv_bEnableVipMenu.BoolValue = false;
				return;
			}
		}
		if (cv_iVipSpawnHP.IntValue >= 1 || cv_fVipSpawnArmour.IntValue >= 1)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", cv_fVipSpawnArmour.IntValue);
			int i_SpawnHealth = GetClientHealth(client);
			SetEntityHealth(client, i_SpawnHealth + cv_iVipSpawnHP.IntValue);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) //RESET BOOLS ON ROUNDSTART AFTER EVENTDAY
{
	if (bEnablePlugin)
	{
		cv_bEnableVipMenu.BoolValue = true;
		bEnablePlugin = false;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) //BUNNY HOP & DoubleJump (Thx to shanapu)
{
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	
	static bool bPressed[MAXPLAYERS + 1] = false;
	
	if (IsPlayerAlive(client))
	{
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			iDJumped[client] = 0;
			bPressed[client] = false;
		}
		else
		{
			if (buttons & IN_JUMP)
			{
				if (water <= 1)
				{
					if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					{
						SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
						if (!(GetEntityFlags(client) & FL_ONGROUND) && bBhop[client])buttons &= ~IN_JUMP;
					}
				}
				
				if (!bDoubleJump[client])return Plugin_Continue;
				
				if (!bPressed[client] && iDJumped[client]++ == 1)
				{
					float velocity[3];
					float velocity0;
					float velocity1;
					float velocity2;
					float velocity2_new;
					
					// Get player velocity
					velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
					velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
					velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
					
					velocity2_new = 200.0;
					
					// calculate new velocity^^
					if (velocity2 < 150.0)velocity2_new = velocity2_new + 20.0;
					
					if (velocity2 < 100.0)velocity2_new = velocity2_new + 30.0;
					
					if (velocity2 < 50.0)velocity2_new = velocity2_new + 40.0;
					
					if (velocity2 < 0.0)velocity2_new = velocity2_new + 50.0;
					
					if (velocity2 < -50.0)velocity2_new = velocity2_new + 60.0;
					
					if (velocity2 < -100.0)velocity2_new = velocity2_new + 70.0;
					
					if (velocity2 < -150.0)velocity2_new = velocity2_new + 80.0;
					
					if (velocity2 < -200.0)velocity2_new = velocity2_new + 90.0;
					
					// Set new velocity
					velocity[0] = velocity0 * 0.1;
					velocity[1] = velocity1 * 0.1;
					velocity[2] = velocity2_new;
					
					// Double Jump
					SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
				}
				
				bPressed[client] = true;
			}
			else bPressed[client] = false;
			
		}
	}
	
	return Plugin_Continue;
}


public void OnClientPutInServer(int client)
{
	CheckTag(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) //HP ON KILL
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (CheckAdminFlag(client, sFlagNeeded) && client == attacker && cv_iVipKillHp.IntValue >= 1)
	{
		int iHealth = GetClientHealth(attacker);
		SetEntityHealth(attacker, cv_iVipKillHp.IntValue + iHealth);
	}
}

public void Event_CheckTag(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, DelayCheck);
}

void CheckTag(int client) //HANDLE TAG
{
	char sVipTag[32];
	cv_sVipTag.GetString(sVipTag, sizeof(sVipTag));
	if (CheckAdminFlag(client, sFlagNeeded) && !StrEqual(sVipTag, "none", false))
		CS_SetClientClanTag(client, sVipTag);
}

public void OnClientPostAdminCheck(int client)
{
	if (CheckAdminFlag(client, sFlagNeeded) && cv_VipJoinMessage.BoolValue)
	{
		char name[32];
		GetClientName(client, name, sizeof(name));
		CPrintToChatAll("[VIP]%N joined in the server!", name);
	}
}

public void OnAvailableLR(int Announced) //DISABLE ITEMS ON LASTREQEST
{
	if (cv_bDisableLR.BoolValue)
	{
		LoopClients(client)
		{
			if (IsPlayerAlive(client))
			{
				iMenuUse[client] = 0;
				bRegen[client] = false;
				bBhop[client] = false;
				if (h_Regen[client] != INVALID_HANDLE)
				{
					KillTimer(h_Regen[client]);
					h_Regen[client] = INVALID_HANDLE;
				}
			}
		}
	}
}

public void OnAllPluginsLoaded()
{
	bIsMYJBAvaible = LibraryExists("myjailbreak");
}

/*public Action OnChatMessage(int & author, ArrayList recipients, eChatFlags & flag, char[] name, char[] message, bool & bProcessColors, bool & bRemoveColors) //VIP TAG IN THE CHAT      *WorkInProgress* NOT TESTED
{
	cv_sVipChatTag.GetString(sVipChatTag, sizeof(sVipChatTag))
	if (CheckVipFlag(client, sFlagNeeded) && !StrEqual(sVipChatTag, "none", false))
		Format(name, MAXLENGTH_NAME, "%t %s", sVipChatTag, name); 
}*/

/********************************************************************************************************************************
                                                              MENU
                                                              
*********************************************************************************************************************************/

void vmenu(int client) //MENU
{
	Menu menu = CreateMenu(hMenu, MENU_ACTIONS_ALL);
	
	Format(sMenuName, sizeof(sMenuName), "%t", "Menu_Title");
	menu.SetTitle(sMenuName);
	if (cv_bMenuLife.BoolValue)
	{
		//menu.AddItem("Life", "+HP");
		AddMenuItemFormat(menu, "Life", ITEMDRAW_DEFAULT, "%t", "Menu_Life");
		
	}
	if (cv_bMenuArmour.BoolValue)
	{
		AddMenuItemFormat(menu, "Armour", ITEMDRAW_DEFAULT, "%t", "Menu_Armour");
	}
	if (cv_bMenuNade.BoolValue)
	{
		AddMenuItemFormat(menu, "Nade", ITEMDRAW_DEFAULT, "%t", "Menu_Granade");
	}
	if (cv_bMenuSmoke.BoolValue)
	{
		AddMenuItemFormat(menu, "Smoke", ITEMDRAW_DEFAULT, "%t", "Menu_Smoke");
	}
	if (cv_bMenuSpeed.BoolValue)
	{
		AddMenuItemFormat(menu, "Speed", ITEMDRAW_DEFAULT, "%t", "Menu_Speed");
		
	}
	if (cv_bMenuGravity.BoolValue)
	{
		AddMenuItemFormat(menu, "Gravity", ITEMDRAW_DEFAULT, "%t", "Menu_Gravity");
	}
	if (cv_bMenuRegen.BoolValue)
	{
		AddMenuItemFormat(menu, "Regen", ITEMDRAW_DEFAULT, "%t", "Menu_Regen");
	}
	
	if (cv_bMenuBhop.BoolValue)
	{
		AddMenuItemFormat(menu, "Bhop", ITEMDRAW_DEFAULT, "%t", "Menu_Bhop");
	}
	
	if (cv_bMenuDobleJump.BoolValue)
	{
		AddMenuItemFormat(menu, "Double", ITEMDRAW_DEFAULT, "%t", "Menu_DoubleJump");
	}
	
	if (StrEqual(sWeapon, "none", false))
	{
		AddMenuItemFormat(menu, "Weap", ITEMDRAW_DEFAULT, "%t", "Menu_Weapon");
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int hMenu(Handle menu, MenuAction action, int client, int param2) //MENU HANDLER
{
	if (action == MenuAction_Select)
	{
		char info[128];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		if (strcmp(info, "Life") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Life");
			int iClientHealth = GetClientHealth(client);
			SetEntProp(client, Prop_Send, "m_iHealth", cv_iLifeHP.IntValue + iClientHealth);
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Armour") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Armour");
			SetEntProp(client, Prop_Send, "m_ArmorValue", cv_iArmour.IntValue);
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Nade") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Nade");
			GivePlayerItem(client, "weapon_hegrenade");
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Smoke") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Smoke");
			GivePlayerItem(client, "weapon_smokegrenade");
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Speed") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Speed");
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", cv_fSpeed.FloatValue);
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Gravity") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Gravity");
			SetEntityGravity(client, cv_fGravity.FloatValue);
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Regen") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Regen");
			bRegen[client] = true;
			h_Regen[client] = CreateTimer(cv_fHpTimer.FloatValue, Timer_Regen, client, TIMER_REPEAT);
			iMenuUse[client]++;
		}
		else if (strcmp(info, "Bhop") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_Bhop");
			bBhop[client] = true;
			iMenuUse[client]++;
		}
		
		else if (strcmp(info, "Double") == 0)
		{
			CPrintToChat(client, "%t %t", "Prefix", "Get_DoubleJump");
			bDoubleJump[client] = true;
			iMenuUse[client]++;
		}
		
		else if (strcmp(info, "Weap") == 0)
		{
			iMenuUse[client]++;
			if (StrContains(sWeapon, "weapon_", true))
			{
				Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
			}
			
			if (GivePlayerItem(client, sWeapon) == -1)
			{
				PrintToConsole(client, "[SM]Invalid Item name/id");
				iMenuUse[client]--;
			}
			else
				PrintToChat(client, "%t %t", "Prefix", "Get_Weapon");
			
		}
		else if (action == MenuAction_End)
		{
			delete menu;
		}
	}
}
/********************************************************************************************************************************
                                                              TIMERS
                                                              
*********************************************************************************************************************************/

public Action Timer_Regen(Handle timer, any client) //REGENERATION TIMER
{
	int iHealth = GetClientHealth(client);
	if (IsValidClientVip(client))
	{
		if (cv_iRegenMaxHP.IntValue < iHealth)
		{
			if (!cv_bStopTimer)
			{
				KillTimer(h_Regen[client]);
			}
			else
				return;
		}
		else if (bRegen[client])
		{
			SetEntityHealth(client, iHealth + cv_iRegenHP.IntValue);
		}
	}
}

public Action DelayCheck(Handle timer)
{
	LoopClients(client)
	{
		if (0 < client)
		{
			CheckTag(client);
		}
	}
	return Action;
}


/********************************************************************************************************************************
                                                              STOCKS
                                                              
*********************************************************************************************************************************/

stock bool IsValidClientVip(int client) //IS VALID CLIENT
{
	if (!(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || GetClientTeam(client) < 2 || IsClientSourceTV(client) || IsClientReplay(client)))
	{
		return false;
	}
	return true;
} 