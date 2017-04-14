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
#pragma deprecated Dont use macro loops
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
#pragma deprecated Dont use macro loops
#define LoopValidClients(%1,%2,%3) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1,%2,%3))

/*************************************** CLIENT ***************************/

/**
 * Check if for a valid client
 *
 *
 * @param client				Client Index
 * @param AllowBots				Allow Bots?
 * @param AllowDead				Allow Dead players?
 * @noreturn
 */
stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/**
 * Checks if user flags
 *
 *
 * @param client			Client Index
 * @param flags				Flags to check, enter comma to separate flags.
 * @return					True if client has the flags, false otherwise.
 */
stock bool CheckAdminFlag(int client, const char[] flags)
{
	if ((GetUserFlagBits(client) & ReadFlagString(flags) == ReadFlagString(flags)) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
		return true;
	}
	return false;
}

/**
 * Get the target client
 *
 * @param client			Client Index
 * @param argnum			Number of the arg
 * @return					True on success, false on failure.
 */
stock int GetTarget(int client, int argnum)
{
	char starget[32];
	
	GetCmdArg(argnum, starget, sizeof(starget));
	int target = FindTarget(client, starget);
	
	return target;
}


/** 
 * Changes a client's name
 *
 * @param client			Client Index
 * @param name				New name
 * @param silent			Silent Name change
 * @noreturn
 */
stock void CS_SetClientName(int client, const char[] name, bool silent = false)
{
	char oldname[MAX_NAME_LENGTH];
	GetClientName(client, oldname, sizeof(oldname));
	
	SetClientInfo(client, "name", name);
	SetEntPropString(client, Prop_Data, "m_szNetname", name);
	
	Handle event = CreateEvent("player_changename");
	
	if (event != INVALID_HANDLE)
	{
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventString(event, "oldname", oldname);
		SetEventString(event, "newname", name);
		FireEvent(event);
	}
	
	if (silent)
		return;
	
	Handle msg = StartMessageAll("SayText2");
	
	if (msg != INVALID_HANDLE)
	{
		BfWriteByte(msg, client);
		BfWriteByte(msg, true);
		BfWriteString(msg, "Cstrike_Name_Change");
		BfWriteString(msg, oldname);
		BfWriteString(msg, name);
		EndMessage();
	}
}



/** 
 * Get alive player count of a team
 *
 * @param client			Team
 * @return					Team Count
 */
stock int GetAliveTeamCount(int team)
{
	int number = 0;
	for (int i; i <= MaxClients; i++)if (IsPlayerAlive(i) && GetClientTeam(i) == team)number++;
	return number;
}




/**
 * Get random alive & non-rebeling player of a team
 *
 *
 * @param team				Team
 * @noreturn
 */
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

/**
 * Get a alive random player of all teams
 *
 * @return					Client Index
 */
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


/*********************************** NUMBERS *****************************/

/**
 * Checks if an number is even
 *
 *
 * @param num				Number to check
 * @return					True if number is even, false otherwise.
 */
stock bool IsEven(int num)
{
	return (num & 1) == 0;
}

/**
 * Checks if an number is odd
 *
 *
 * @param num				Number to check
 * @return					True if number is odd, false otherwise.
 */
stock bool IsOdd(int num)
{
	return (num & 1) == 1;
}

/********************************** WEAPONS ********************************/


/**
 * Strip All Weapons & the knife slot twice for taser
 *
 *
 * @param client				Client Index
 * @noreturn
 */
stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	for (int i = 1; i <= 4; i++)
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

/** 
 * Gives an Item to a client with custom ammos
 *
 * @param client			Client Index
 * @param weapon			Weapon Name
 * @param clip				Ammo ammount in the clip
 * @param ammo				Total ammo ammount
 * @return					Weapon Index
 */
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

/** 
 * Set ammo account for a weapon
 *
 * @param client			Client Index
 * @param weapon			Weapon INdex
 * @param clip				Ammo ammount in the clip
 * @param ammo				Total ammo ammount
 * @noreturn
 */
stock void SetPlayerWeaponAmmo(int client, int weaponEnt, int clip = -1, int ammo = -1)
{
	if (weaponEnt == INVALID_ENT_REFERENCE)
		return;
	
	if (clip != -1)
		SetEntProp(weaponEnt, Prop_Send, "m_iClip1", clip);
	
	if (ammo != -1) {
		int iOffset = FindDataMapOffs(client, "m_iAmmo") + (GetEntProp(weaponEnt, Prop_Data, "m_iPrimaryAmmoType") * 4);
		SetEntData(client, iOffset, ammo, 4, true);
		
		if (GetEngineVersion() == Engine_CSGO) {
			SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		}
	}
}


/** 
 * Gives an Item to a client removing the current weapon
 *
 * @param client			Client Index
 * @param weapon			
 * @return					Iteam Index
 */
stock int GivePlayerItemRemove(int client, int weapon, int slot)
{
	if ((weapon = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	return GivePlayerItem(client, weapon);
}

/****************************** COMMAND ARGS **************************/


/** 
 * Retrives a command argument given its index as int, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Int Value of Arg
 */
stock int GetCmdArgInt(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToInt(value);
}

/** 
 * Retrives a command argument given its index as float, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Float Value of Arg
 */
stock float GetCmdArgFloat(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToFloat(value);
}

/** 
 * Retrives a command argument given its index as bool, from the console or server command
 *
 * @param argnum			Arg number
 * @return					Bool Value of Arg
 */
stock bool GetCmdArgBool(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return view_as<bool>(StringToInt(value));
}

/********************************** CVARS **************************************/

/**
 * Easy silent change of ConVars - Boolean
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
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



/**
 * Easy silent change of ConVars - Floats
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
stock void SetCvarFloat(char cvarName[64], float value)
{
	Handle FloatCvar = FindConVar(cvarName);
	if (FloatCvar == INVALID_HANDLE)return;
	
	int flags = GetConVarFlags(FloatCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
	
	SetConVarFloat(FloatCvar, value);
	
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(FloatCvar, flags);
}



/**
 * Easy silent change of ConVars - Strings
 *
 *
 * @param cvarName				Name of cvar
 * @param value					New value of cvar
 * @noreturn
 */
stock void SetCvarString(char cvarName[64], char[] value)
{
	Handle cvar = FindConVar(cvarName);
	SetConVarString(cvar, value, true);
}


/********************************************** ENTITIES *********************************************/


/** 
 * Sets an entity's speed
 *
 * @param entity			Entity Index
 * @param speed				Speed to set
 * @noreturn
 */
public void SetEntitySpeed(int entity, float speed)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", speed);
}

/** 
 * Gets an entity's Speed
 *
 * @param entity			Entity Index
 * @return					Amount of Speed
 */
public float GetEntitySpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue");
}

/** 
 * Sets an entity's armour
 *
 * @param entity			Entity Index
 * @param armour			Armour to set
 * @noreturn
 */
public void SetEntityArmour(int entity, float armour)
{
	SetEntProp(entity, Prop_Send, "m_ArmorValue", armour);
}

/** 
 * Gets an entity's Armour
 *
 * @param entity			Entity Index
 * @return					Amount of Armour
 */
public int GetEntityArmour(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_ArmorValue");
}

/********************************** MISC *********************************/

/**
 * Better Kill of a Timer
 *
 *
 * @param TimerHandler		Handle of the timer
 * @noreturn
 */
stock void StopTimer(Handle &TimerHandle)
{
	KillTimer(&TimerHandle);
	&TimerHandle = INVALID_HANDLE;
}

/** Reset client Render Color
 * 
 *
 *
 * @param num				Client Index
 * @noreturn
 */
stock void ResetRenderColor(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
}


/**
 * Appends a new item to the end of a menu with a format.
 *
 * @param menu				Menu Handle.
 * @param info				Item information string.
 * @param display			Default item display string.
 * @param style				Drawing style flags.  Anything other than DEFAULT or 
 * @param format			Formatting rules
 * @param ...				Variable number of format parameters
 * @return					True on success, false on failure.
 * @error					Invalid Handle or item limit reached.
 */
stock bool AddMenuItemFormat(Handle menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any...)
{
	char display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return AddMenuItem(menu, info, display, style);
}
