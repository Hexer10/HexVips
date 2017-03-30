/*
**
*/
#if defined _hexstocks_included
#endinput
#endif
#define _hexstocks_included

/*
INCLUDE MERGE OF MYSTOCKS(shanpu)teamgames-stocks/menu-stocks(KissLick) & some other!
*/

//Easy loops
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
#define LoopValidClients(%1,%2,%3) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1,%2,%3))


stock bool IsEven(int num)
{
    return (num & 1) == 0;
}

stock bool IsOdd(int num)
{
    return (num & 1) == 1;
}  


stock void StopTimer(Handle TimerHandle)
{
	KillTimer(TimerHandle);
	TimerHandle = INVALID_HANDLE;
}

//Reset Render Color
stock void ResetRenderColor(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
}
//Check Engine
stock void CheckEngine()
{
	EngineVersion g_Game;
	
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");
	}
}

//Get a player for a certain admin flag
stock bool CheckAdminFlag(int client, const char[] flagsNeed)
{
	if ((GetUserFlagBits(client) & ReadFlagString(flagsNeed) == ReadFlagString(flagsNeed)) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
		return true;
	}
	return false;
}

//Strip All Weapons & the knife slot twice for taser
stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 0; i <= 4; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(weapon, "Kill");
		}
	}
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1) //strip knife slot 2 times for taser
	{
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(weapon, "Kill");
	}
}

//Get random alive & non-rebeling player of a team
stock int GetRandomPlayer(int team)
{
	int[] clients = new int[MaxClients];
	int clientCount;
	LoopClients(i)
	{
		if ((GetClientTeam(i) == team) && IsPlayerAlive(i) && !IsClientRebel(i))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}

//Easy silent change of ConVars - Boolean
stock void SetCvar(char cvarName[64], int value)
{
	Handle IntCvar = FindConVar(cvarName);
	if (IntCvar == null)return;
	
	int flags = GetConVarFlags(IntCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
	
	SetConVarInt(IntCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(IntCvar, flags);
}


//Easy silent change of ConVars - Floats
stock void SetCvarFloat(char cvarName[64], float value)
{
	Handle FloatCvar = FindConVar(cvarName);
	if (FloatCvar == INVALID_HANDLE)return;
	
	new flags = GetConVarFlags(FloatCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
	
	SetConVarFloat(FloatCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
}


//Easy silent change of ConVars - Strings
stock void SetCvarString(char cvarName[64], char[] value)
{
	Handle cvar = FindConVar(cvarName);
	SetConVarString(cvar, value, true);
}


//Check for clients
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}


stock bool:AddMenuItemFormat(&Handle:menu, const String:info[], style = ITEMDRAW_DEFAULT, const String:format[], any:...)
{
	decl String:display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return bool:AddMenuItem(menu, info, display, style);
}

//Get Target
stock int GetTarget(int client, int argnum)
{
	char starget[32];
	
	GetCmdArg(argnum, starget, sizeof(starget));
	int target = FindTarget(client, starget);
	
	
	if (target == -1)
	{
		ReplyToCommand(client, "Client non trovato");
		return -1;
	}
	
	return target;
}




stock GetCmdArgInt(argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToInt(value);
}

stock GetCmdArgFloat(argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToFloat(value);
}

stock int GivePlayerItemRemove(int client, int weapon, int slot)
{
		if ((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
		GivePlayerItem(client, weapon);
}

//Give player Iteam w/ Ammo
stock int GivePlayerWeaponAndAmmo(int client, const char[] weapon, int clip = -1, int ammo = -1)
{
	int weaponEnt = GivePlayerItem(client, weapon);
	
	if (weaponEnt != -1) {
		if (clip != -1)
			SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);
		
		if (ammo != -1) {
			int iOffset = FindDataMapInfo(client, "m_iAmmo") + (GetEntProp(weaponEnt, Prop_Data, "m_iPrimaryAmmoType") * 4);
			SetEntData(client, iOffset, ammo, 4, true);
			
			if (GetEngineVersion() == Engine_CSGO) {
				SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
			}
		}
	}
	
	return weaponEnt;
}

//Set weapon ammo
stock SetPlayerWeaponAmmo(client, weaponEnt, clip = -1, ammo = -1)
{
	if (weaponEnt == INVALID_ENT_REFERENCE)
		return;
	
	if (clip != -1)
		SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);
	
	if (ammo != -1) {
		new iOffset = FindDataMapOffs(client, "m_iAmmo") + (GetEntProp(weaponEnt, Prop_Data, "m_iPrimaryAmmoType") * 4);
		SetEntData(client, iOffset, ammo, 4, true);
		
		if (GetEngineVersion() == Engine_CSGO) {
			SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		}
	}
}


//Get alive player count of a team
stock int GetAliveTeamCount(int team)
{
	int number = 0;
	LoopClients(i)if (IsPlayerAlive(i) && GetClientTeam(i) == team)number++;
	return number;
}


//Get a alive random player of all teams
stock int GetRandomAlivePlayer()
{
	int[] clients = new int[MaxClients];
	int clientCount;
	LoopClients(i)
	{
		if (IsPlayerAlive(i))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}

public void SetEntitySpeed(int entity, float speed)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", speed);
}

public float GetEntitySpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue");
}

public void SetEntityArmour(int entity, float armour)
{
	SetEntProp(entity, Prop_Send, "m_ArmorValue", armour);
}

public int GetEntityArmour(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_ArmorValue");
}


/**
 * Checks if string str starts with subString. Forked from smlib
 *
 *
 * @param str				String to check
 * @param subString			Sub-String to check in str
 * @return					True if str starts with subString, false otherwise.
 */
stock bool String_StartsWith(const char[] str, const char[] subString)
{
	int n = 0;
	while (subString[n] != '\0') {
		
		if (str[n] == '\0' || str[n] != subString[n]) {
			return false;
		}
		
		n++;
	}
	
	return true;
}


