/*
 * VipMenu-Bonuses - API (Include) Plugin.
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
 
#if defined _vipbonus_included_
	#endinput
#endif
#define _vipbonus_included_


/**
 * Return if a certain player is VIP or not
 * @param client		Client Index.
 *
 * @return 				True if a client has VipAccess, false otherwise.
 */
native bool Vip_IsClientVip(int client);

/**
 * Reset all the VipMenu Items of a certain player 
 * @param client		Client Index.
 * @noreturn
 */
native void Vip_ResetItems(int client);

/**
 * Called when the VipBonuses are assigned to a client.
 * @param client		Client Index.
 * @return 				Plugin_Handled to block or Plugin_Continue to allow.
 */
forward Action Vip_OnBonusSet(int client);


/**
 * Called when a client uses the VipMenu
 * @param client		Client Index.
 * @param item			Item Used
 * @noreturn
 */
forward void Vip_OnPlayerUseMenu(int client, const char[] item);


public SharedPlugin __pl_vipbonus =
{
	name = "VipBonus",
	file = "VipBonus.smx",
	
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};