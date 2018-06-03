/*
 * HexVips - VipMenu Plugin.
 * by: Hexer10
 * https://github.com/Hexer10/HexVips
 * 
 * Copyright (C) 2016-2017 Mattia (Hexer10 | Hexah | Papero)
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



//#include "VipBonus.sp"

//Defines
#define HEAVY_MODEL "models/player/custom_player/legacy/tm_phoenix_heavy.mdl"

//Bool
bool bRegen[MAXPLAYERS + 1] = false;
bool bBhop[MAXPLAYERS + 1] = false;
bool bDoubleJump[MAXPLAYERS + 1] = false;
bool bResetGravity[MAXPLAYERS + 1] = false;
bool bUsed[MAXPLAYERS + 1][13];
/*
0 - Life
1 - Armour
2 - Nade
3 - Smoke
4 - NadeKit
5 - Speed
6 - Gravity
7 - Regen
8 - Bhop
9 - Double
10 - Weapon
11 - Respawn
12 - Heavy
*/

//Handle
Handle hRegenTimer[MAXPLAYERS + 1];

//Int
int iMenuUse[MAXPLAYERS + 1] = 0;
int iDJumped[MAXPLAYERS + 1] = 0;

//Bool
bool bIsLR = false;
bool bCanRespawn[MAXPLAYERS + 1] = false;

//String
char sMenuName[32];

//ConVar bool
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
ConVar cv_bMenuNadeKit;
ConVar cv_bMenuRespawn;
ConVar cv_bMenuHeavy;
ConVar cv_bMenuDoubleUses;
ConVar cv_bStopTimer;
ConVar cv_bDisableLR;

//ConVar int
ConVar cv_iRegenMaxHP;
ConVar cv_iRegenHP;
ConVar cv_iLifeHP;
ConVar cv_iArmour;
ConVar cv_iMenuUse;
ConVar cv_iLifeTeam;
ConVar cv_iArmourTeam;
ConVar cv_iGravityTeam;
ConVar cv_iSpeedTeam;
ConVar cv_iNadeTeam;
ConVar cv_iSmokeTeam;
ConVar cv_iRegenTeam;
ConVar cv_iBhopTeam;
ConVar cv_iDoubleTeam;
ConVar cv_iWeapTeam;
ConVar cv_iNadeMolotov;
ConVar cv_iNadeSmoke;
ConVar cv_iNadeFlashbang;
ConVar cv_iNadeHE;
ConVar cv_iNadeTag;
ConVar cv_iNadeKitTeam;
ConVar cv_iRespawnTeam;
ConVar cv_iHeavyTeam;

//ConVar float
ConVar cv_fHpTimer;
ConVar cv_fSpeed;
ConVar cv_fGravity;

//ConVar String
ConVar cv_sVipMenuComm;
ConVar cv_sWeapon;

public void OnVipMenuStart()
{
	RegConsoleCmd("sm_vipmenu", Command_VipMenu, "Open VipMenu for VIPs");
	RegAdminCmd("sm_resetvipmenu", Command_ResMenu, ADMFLAG_CONFIG, "Reset VIPMenu advantages (Weapons remains)");
	
	AutoExecConfig_SetFile("VipMenu", "HexVips");
	AutoExecConfig_SetCreateFile(true);
	cv_bEnableVipMenu = AutoExecConfig_CreateConVar("vip_menu_vipmenu", "1", " 1 - Enable VipMenu. 0 - Disable", 0, true, 0.0, true, 1.0);
	cv_sVipMenuComm = AutoExecConfig_CreateConVar("vip_menu_vipmenucmds", "vmenu", "Commands to open the Vipmenu (no need of sm_ or ! or /)(separeted by a comma ',')");
	cv_iMenuUse = AutoExecConfig_CreateConVar("vip_menu_uses", "1", "Max VipMenu uses per round", 0, true, 0.0);
	cv_bMenuDoubleUses = AutoExecConfig_CreateConVar("vip_menu_use_once", "1", " 1 - Same item can be used only once. 0 - Same item can be used multiple times", 0, true, 0.0, true, 1.0);
	cv_bDisableLR = AutoExecConfig_CreateConVar("vip_menu_disable_lr", "1", "Disable VipMenu in sm_hosties LR", 0, true, 0.0, true, 1.0);
	cv_bMenuLife = AutoExecConfig_CreateConVar("vip_menu_life", "1", " 1 - Enable VipMenu Life. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_iLifeHP = AutoExecConfig_CreateConVar("vip_menu_life_amount", "50", "Amount +HP");
	cv_bMenuArmour = AutoExecConfig_CreateConVar("vip_menu_armour", "1", " 1 - Enable VipMenu Armour. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_iArmour = AutoExecConfig_CreateConVar("vip_menu_armour_amount", "50", "Amount +Armour");
	cv_bMenuGravity = AutoExecConfig_CreateConVar("vip_menu_gravity", "1", " 1 - Enable VipMenu Gravity. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_fGravity = AutoExecConfig_CreateConVar("vip_menu_gravity_amount", "0.5", "Amount Gravity");
	cv_bMenuSpeed = AutoExecConfig_CreateConVar("vip_menu_speed", "1", " 1 - Enable VipMenu Speed. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_fSpeed = AutoExecConfig_CreateConVar("vip_menu_speed_amount", "1.5", "Amount Speed");
	cv_bMenuNade = AutoExecConfig_CreateConVar("vip_menu_he", "0", " 1 - Enable VipMenu HE Nade. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_bMenuSmoke = AutoExecConfig_CreateConVar("vip_menu_smoke", "0", " 1 - Enable VipMenu Smoke. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_bMenuNadeKit = AutoExecConfig_CreateConVar("vip_menu_nadekit", "1", " 1 - Enable NadeKit. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_iNadeMolotov = AutoExecConfig_CreateConVar("vip_menu_cn_molotov_amount", "1", "Amount of molotovs for NadeKit.", 0, true, 0.0, true, 10.0);
	cv_iNadeFlashbang = AutoExecConfig_CreateConVar("vip_menu_cn_flash_amount", "1", "Amount of flash for NadeKit.", 0, true, 0.0, true, 10.0);
	cv_iNadeHE = AutoExecConfig_CreateConVar("vip_menu_cn_he_amount", "1", "Amount of he for NadeKit", 0, true, 0.0, true, 10.0);
	cv_iNadeSmoke = AutoExecConfig_CreateConVar("vip_menu_cn_smoke_amount", "1", "Amount of smoke for NadeKit", 0, true, 0.0, true, 10.0);
	cv_iNadeTag = AutoExecConfig_CreateConVar("vip_menu_cn_tag_amount", "0", "Amount of tagrenades for NadeKit", 0, true, 0.0, true, 10.0);
	cv_bMenuBhop = AutoExecConfig_CreateConVar("vip_menu_bhop", "1", " 1 - Enable VipMenu Bhop. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_bMenuDobleJump = AutoExecConfig_CreateConVar("vip_menu_doublejump", "1", " 1 - Enable DoubleJump Life. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_sWeapon = AutoExecConfig_CreateConVar("vip_menu_weapon", "glock", " WEAPONNAME - Weapon to get. None - Disable. ( Weapon list: https://developer.valvesoftware.com/wiki/List_of_Counter-Strike:_Global_Offensive_Entities . Under Weapon tag) [NO NEED weapon_ ]");
	cv_bMenuRegen = AutoExecConfig_CreateConVar("vip_menu_regen", "1", " 1 - Enable VipMenu Regen. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_iRegenMaxHP = AutoExecConfig_CreateConVar("vip_menu_regen_maxhp", "200", "Max Regen HP");
	cv_fHpTimer = AutoExecConfig_CreateConVar("vip_menu_regen_interval", "1.0", "Regen interval");
	cv_iRegenHP = AutoExecConfig_CreateConVar("vip_menu_regen_hp", "10", "Regen +HP");
	cv_bStopTimer = AutoExecConfig_CreateConVar("vip_menu_regen_stop", "0", " 0 - Stop Regen when reached max. 1 - Continue when get lower MaxHP", 0, true, 0.0, true, 1.0);
	cv_bMenuRespawn = AutoExecConfig_CreateConVar("vip_menu_respawn", "0", " 1 - Enable VipMenu Respawn. 0 - Disable", 0, true, 0.0, true, 1.0);
	cv_bMenuHeavy = AutoExecConfig_CreateConVar("vip_menu_heavy", "0", " 0 - Enable Heavy. 0 - Disable ", 0, true, 0.0, true, 1.0);
	cv_iLifeTeam = AutoExecConfig_CreateConVar("vip_menu_team_life", "3", "Team to use Life. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iArmourTeam = AutoExecConfig_CreateConVar("vip_menu_team_armour", "3", "Team to use Armour. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iGravityTeam = AutoExecConfig_CreateConVar("vip_menu_team_gravity", "3", "Team to use Gravity. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iSpeedTeam = AutoExecConfig_CreateConVar("vip_menu_team_speed", "3", "Team to use Speed. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iNadeTeam = AutoExecConfig_CreateConVar("vip_menu_team_he", "3", "Team to use HeNade. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iSmokeTeam = AutoExecConfig_CreateConVar("vip_menu_team_smoke", "3", "Team to use Smoke. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iNadeKitTeam = AutoExecConfig_CreateConVar("vip_menu_team_nadekit", "3", "Team to use NadeKit. 1 = T 2 = CT 3 = BOTH", 0, true, 1.0, true, 3.0);
	cv_iBhopTeam = AutoExecConfig_CreateConVar("vip_menu_team_bhop", "3", "Team to use Bhop. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iDoubleTeam = AutoExecConfig_CreateConVar("vip_menu_team_doublejump", "3", "Team to use DoubleJump. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iRegenTeam = AutoExecConfig_CreateConVar("vip_menu_team_regen", "3", "Team to use Regen. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iWeapTeam = AutoExecConfig_CreateConVar("vip_menu_team_customweapon", "3", "Team to use CustomWeapon. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iRespawnTeam = AutoExecConfig_CreateConVar("vip_menu_team_respawn", "3", "Team to use Respawn. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	cv_iHeavyTeam =  AutoExecConfig_CreateConVar("vip_menu_team_heavy", "3", "Team to use Respawn. 1 = T 2 = CT 3 = Both", 0, true, 1.0, true, 3.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	
	HookEvent("player_spawn", Menu_PlayerSpawn);
	HookEvent("player_death", Menu_PlayerDeath);
}

public void OnMapStart()
{
	PrecacheModel(HEAVY_MODEL);
}

/********************************************************************************************************************************
                                                              COMMANDS
                                                              
*********************************************************************************************************************************/


public Action Command_ResMenu(int client, int args)
{
	if (args == 0)
	{
		CReplyToCommand(client, "Usage: !resetvipmenu < client/target > < 1 = silent >");
		return Plugin_Handled;
	}
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
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int iSilent = GetCmdArgInt(3);
	for (int i = 0; i < target_count; i++)
	{
		if (iSilent != 1)
		{
			CPrintToChat(target_list[i], "%t", "Reseted_Usage", client);
			CReplyToCommand(client, "%t", "Reseted_Usage_Of", target_list[i]);
		}
		
		HexVips_ResetItems(target_list[i]);
		
	}
	return Plugin_Handled;
}

public Action Command_VipMenu(int client, int args)
{
	if (!cv_bPluginEnable.BoolValue)
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Plugin_Disabled");
		return Plugin_Handled;
	}
	if (!client)
	{
		ReplyToCommand(client, "[SM] This command in in-game only!");
		return Plugin_Handled;
	}
	if (!HexVips_IsClientVip(client))
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Not_VIP");
		return Plugin_Handled;
	}
	if (!cv_bEnableVipMenu.BoolValue)
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Plugin_Disable");
		return Plugin_Handled;
	}
	if (bIsMYJBAvaible && cv_bDisableOnEventday.BoolValue)
	{
		if (MyJailbreak_IsEventDayRunning())
		{
			CReplyToCommand(client, "%t %t", "Prefix", "MYJBEvent_Running");
			return Plugin_Handled;
		}
	}
	if (bIsLRAvaible && cv_bDisableLR.BoolValue)
	{
		if (bIsLR)
		{
			CReplyToCommand(client, "%t %t", "Prefix", "HostiesLR_Active");
			return Plugin_Handled;
		}
	}
	
	if (!IsPlayerAlive(client)) //Alive check
	{
		if (bCanRespawn[client])
		{
			vrespawnmenu(client);
			return Plugin_Handled;
		}
		CReplyToCommand(client, "%t %t", "Prefix", "Player_Death");
		return Plugin_Handled;
	}
	if (iMenuUse[client] == cv_iMenuUse.IntValue)
	{
		CReplyToCommand(client, "%t %t", "Prefix", "Menu_Already");
		return Plugin_Handled;
	}
	vmenu(client);
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	//Custom Comm (forked from shanapu)
	int iCount = 0;
	char sCommands[128], sCommandsL[12][32], sCommand[32];
	cv_sVipMenuComm.GetString(sCommands, sizeof(sCommands));
	ReplaceString(sCommands, sizeof(sCommands), " ", "");
	iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
	for (int i = 0; i < iCount; i++)
	{
		Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
		if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS) // if command not already exist
		{
			RegConsoleCmd(sCommand, Command_VipMenu, "Opens VipMenu");
		}
	}
	
}




/********************************************************************************************************************************
                                                              MENU
                                                              
*********************************************************************************************************************************/


void vrespawnmenu(int client)
{
	Menu menu = CreateMenu(hRespawnMenu, MENU_ACTIONS_ALL);
	Format(sMenuName, sizeof(sMenuName), "%t", "Menu_Title");
	menu.SetTitle(sMenuName);
	AddMenuItemFormat(menu, "Respawn", ITEMDRAW_DEFAULT, "%t", "Menu_Respawn");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int hRespawnMenu(Handle menu, MenuAction action, int client, int param2) //MENU HANDLER
{
	if (action == MenuAction_Select)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i))
		{
			if (i != client)
			{
				PrintToChat(i, "%t %t", "Prefix", "Vip_Respawn_All", client);
			}
		}
		PrintToChat(client, "%t %t", "Prefix", "Vip_Respawn");
		bCanRespawn[client] = false;
		CS_RespawnPlayer(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	
}
void vmenu(int client) //MENU
{
	Menu menu = new Menu(hMenu);
	Format(sMenuName, sizeof(sMenuName), "%t", "Menu_Title");
	menu.SetTitle(sMenuName);
	
	if (!cv_bMenuDoubleUses.BoolValue)
	{
		for (int i = 0; i < sizeof(bUsed[]); i++)
		{
			bUsed[client][i] = false;
		}
	}
	
	char sWeapon[32];
	cv_sWeapon.GetString(sWeapon, sizeof(sWeapon));
	TrimString(sWeapon);
	
	if (cv_bMenuLife.BoolValue && IsValidTeam(client, cv_iLifeTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Life", bUsed[client][0] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Life");
	}
	if (cv_bMenuArmour.BoolValue && IsValidTeam(client, cv_iArmourTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Armour", bUsed[client][1] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Armour");
	}
	
	if (cv_bMenuNade.BoolValue && IsValidTeam(client, cv_iNadeTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Nade", bUsed[client][2] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Granade");
	}
	
	if (cv_bMenuSmoke.BoolValue && IsValidTeam(client, cv_iSmokeTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Smoke", bUsed[client][3] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Smoke");
	}
	if (cv_bMenuNadeKit.BoolValue && IsValidTeam(client, cv_iNadeKitTeam.IntValue) && ((cv_iNadeMolotov.IntValue + cv_iNadeFlashbang.IntValue + cv_iNadeHE.IntValue + cv_iNadeSmoke.IntValue) > 0))
	{
		AddMenuItemFormat(menu, "NadeKit", bUsed[client][4] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_NadeKit");
	}
	if (cv_bMenuSpeed.BoolValue && IsValidTeam(client, cv_iSpeedTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Speed", bUsed[client][5] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Speed");
	}
	if (cv_bMenuGravity.BoolValue && IsValidTeam(client, cv_iGravityTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Gravity", bUsed[client][6] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Gravity");
	}
	if (cv_bMenuRegen.BoolValue && IsValidTeam(client, cv_iRegenTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Regen", bUsed[client][7] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Regen");
	}
	if (cv_bMenuBhop.BoolValue && IsValidTeam(client, cv_iBhopTeam.IntValue) && !cv_bAlwaysBhop.BoolValue)
	{
		AddMenuItemFormat(menu, "Bhop", bUsed[client][8] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Bhop");
	}
	if (cv_bMenuDobleJump.BoolValue && IsValidTeam(client, cv_iDoubleTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Double", bUsed[client][9] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_DoubleJump");
	}
	if (!StrEqual(sWeapon, "", false) && IsValidTeam(client, cv_iWeapTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Weap", bUsed[client][10] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Weapon");
	}
	if (cv_bMenuRespawn.BoolValue && IsValidTeam(client, cv_iRespawnTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Respawn", bUsed[client][11] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Respawn");
	}
	if (cv_bMenuHeavy.BoolValue && IsValidTeam(client, cv_iHeavyTeam.IntValue))
	{
		AddMenuItemFormat(menu, "Heavy", bUsed[client][12] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "%t", "Menu_Heavy");
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
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Life");
			int iClientHealth = GetClientHealth(client);
			if (iClientHealth < 100)
				iClientHealth = iClientHealth + (100 - iClientHealth);
			SetEntProp(client, Prop_Send, "m_iHealth", cv_iLifeHP.IntValue + iClientHealth);
			iMenuUse[client]++;
			bUsed[client][0] = true;
		}
		else if (strcmp(info, "Armour") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Armour");
			SetEntProp(client, Prop_Send, "m_ArmorValue", cv_iArmour.IntValue);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			iMenuUse[client]++;
			bUsed[client][1] = true;
		}
		else if (strcmp(info, "Nade") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Nade");
			GivePlayerItem(client, "weapon_hegrenade");
			iMenuUse[client]++;
			bUsed[client][2] = true;
		}
		else if (strcmp(info, "Smoke") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Smoke");
			GivePlayerItem(client, "weapon_smokegrenade");
			iMenuUse[client]++;
			bUsed[client][3] = true;
		}
		else if (strcmp(info, "Speed") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Speed");
			SetEntitySpeed(client, cv_fSpeed.FloatValue);
			iMenuUse[client]++;
			bUsed[client][5] = true;
		}
		else if (strcmp(info, "Gravity") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Gravity");
			SetEntityGravity(client, cv_fGravity.FloatValue);
			iMenuUse[client]++;
			bResetGravity[client] = true;
			bUsed[client][6] = true;
		}
		else if (strcmp(info, "Regen") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Regen");
			bRegen[client] = true;
			if (hRegenTimer[client] != INVALID_HANDLE)
			{
				hRegenTimer[client].Close();
				hRegenTimer[client] = INVALID_HANDLE;
			}
			hRegenTimer[client] = CreateTimer(cv_fHpTimer.FloatValue, Timer_Regen, GetClientUserId(client), TIMER_REPEAT);
			iMenuUse[client]++;
			bUsed[client][7] = true;
		}
		else if (strcmp(info, "Bhop") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Bhop");
			bBhop[client] = true;
			iMenuUse[client]++;
			bUsed[client][8] = true;
		}
		
		else if (strcmp(info, "Double") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			CPrintToChat(client, "%t %t", "Prefix", "Get_DoubleJump");
			bDoubleJump[client] = true;
			iMenuUse[client]++;
			bUsed[client][9] = true;
		}
		
		else if (strcmp(info, "NadeKit") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			iMenuUse[client]++;
			bUsed[client][4] = true;
			if (cv_iNadeMolotov.IntValue != 0)
			{
				if (GetClientTeam(client) == CS_TEAM_T)
				{
					GivePlayerItemAmmo(client, "weapon_molotov", 1, cv_iNadeMolotov.IntValue);
				}
				else if (GetClientTeam(client) == CS_TEAM_CT)
				{
					GivePlayerItemAmmo(client, "weapon_incgrenade", 1, cv_iNadeMolotov.IntValue);
				} 
			}
			if (cv_iNadeFlashbang.IntValue != 0)
			{
				GivePlayerItemAmmo(client, "weapon_flashbang", 1, cv_iNadeFlashbang.IntValue);
			}
			if (cv_iNadeHE.IntValue != 0)
			{
				GivePlayerItemAmmo(client, "weapon_hegrenade", 1, cv_iNadeHE.IntValue);
			}
			if (cv_iNadeSmoke.IntValue != 0)
			{
				GivePlayerItemAmmo(client, "weapon_smokegrenade", 1, cv_iNadeSmoke.IntValue);
			}
			if (cv_iNadeTag.IntValue != 0)
			{
				GivePlayerItemAmmo(client, "weapon_tagrenade", 1, cv_iNadeTag.IntValue);
			}
			
			CPrintToChat(client, "%t %t", "Prefix", "Get_NadeKit");
		}
		
		else if (strcmp(info, "Weap") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			iMenuUse[client]++;
			bUsed[client][10] = true;
			char sWeapon[32];
			cv_sWeapon.GetString(sWeapon, sizeof(sWeapon));
			if (StrContains(sWeapon, "weapon_", true))
			{
				Format(sWeapon, sizeof(sWeapon), "weapon_%s", sWeapon);
			}
			
			if (GivePlayerItem(client, sWeapon) == -1)
			{
				iMenuUse[client]--;				
				PrintToChat(client, "Error: Invalid Item name/id");
				LogError("Error occured while giving %s to %n, INVALID ITEM ID/NAME", sWeapon, client);
			}
			else
			{
				CPrintToChat(client, "%t %t", "Prefix", "Get_Weapon");
			}	
		}
		
		else if (strcmp(info, "Respawn") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			iMenuUse[client]++;
			bUsed[client][11] = true;
			bCanRespawn[client] = true;
			CPrintToChat(client, "%t %t", "Prefix", "Get_Respawn");
		}
		
		else if (strcmp(info, "Heavy") == 0)
		{
			Forward_OnPlayerUseMenu(client, info);
			iMenuUse[client]++;
			bUsed[client][12] = true;
			SetEntityModel(client, HEAVY_MODEL);
			GivePlayerItem(client, "item_heavyassaultsuit");
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			CPrintToChat(client, "%t %t", "Prefix", "Get_Heavy");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/********************************************************************************************************************************
                                                              EVENTS
                                                              
*********************************************************************************************************************************/

public void Menu_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsValidClient(client, false, true))
		return;
	
	if (bResetGravity[client])
	{
		SetEntityGravity(client, 1.0);
		bResetGravity[client] = false;
	}
		
	for (int i = 0; i < sizeof(bUsed[]); i++)
		bUsed[i][client] = false;
		
	iMenuUse[client] = 0;
	bRegen[client] = false;
	bBhop[client] = false;
	bDoubleJump[client] = false;
	
	if (hRegenTimer[client] != INVALID_HANDLE)
	{
		hRegenTimer[client].Close();
		hRegenTimer[client] = INVALID_HANDLE;
	}
	
}


public Action Menu_OnPlayerRunCmd(int client, int buttons) //DoubleJump & Bhop forked from shanapu!
{
	int water = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	
	// Last button
	static bool bPressed[MAXPLAYERS + 1] = false;
	
	if (IsPlayerAlive(client))
	{
		// Reset when on Ground
		if (GetEntityFlags(client) & FL_ONGROUND)
		{
			iDJumped[client] = 0;
			bPressed[client] = false;
		}
		else
		{
			// Player pressed jump button?
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
				
				if (!iDJumped[client])return Plugin_Continue;
				
				// For second time?
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


public void Menu_PlayerDeath(Event event, const char[] name, bool dontBroadcast) //HP ON KILL
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (bCanRespawn[client])
	{
		CPrintToChat(client, "%t %t", "Prefix", "Can_Respawn");
	}
	
	if (hRegenTimer[client] != INVALID_HANDLE)
	{
		hRegenTimer[client].Close();
		hRegenTimer[client] = INVALID_HANDLE;
	}
}

public void OnAvailableLR(int Announced)
{
	bIsLR = true;
}

/********************************************************************************************************************************
                                                              TIMERS
                                                              
*********************************************************************************************************************************/

public Action Timer_Regen(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client, false, false))
		return Plugin_Continue;
	int iHealth = GetClientHealth(client);
	if (IsValidClient(client))
	{
		if (!bRegen[client])
		{
			hRegenTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		if (cv_iRegenMaxHP.IntValue > iHealth)
		{
			if (bRegen[client])
			{
				SetEntityHealth(client, iHealth + cv_iRegenHP.IntValue);
				return Plugin_Continue;
			}
		}
		
		if (!cv_bStopTimer.BoolValue)
		{
			hRegenTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
		else
			return Plugin_Continue;
	}
	else
	{
		hRegenTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}

/********************************************************************************************************************************
                                                              API
                                                              
*********************************************************************************************************************************/


void Forward_OnPlayerUseMenu(int client, const char[] item)
{
	Call_StartForward(fOnPlayerUseMenu);
	Call_PushCell(client);
	Call_PushString(item);
	Call_Finish();
	
} 