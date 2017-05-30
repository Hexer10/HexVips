/*
**
*/
#if defined _vipbonus_included_
	#endinput
#endif
#define _vipbonus_included_


public SharedPlugin __pl_vipbonus =
{
	name = "vipbonus",
	file = "vipbonus.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};


/**
 * @param client		Client Index.
 *
 * @return 				True if a client has VipAccess, false otherwise.
 */
native bool IsClientVip(int client);

/**
 * Called when the VipBonuses are assigned to a client.
 * @param client		Client Index.
 * @return 				Plugin_Handled to block or Plugin_Continue to allow.
 */
forward Action OnVipBonusAssiged(int client);