#include <amxmodx>

#define PLUGIN	"Show The top3 Damage dealer"
#define VERSION	"1.0"
#define AUTHOR	"Nailaz"

new Float:g_damage[33], Float:g_player_dmg[3]
new g_Sync, g_MaxP
new l_hud_x, l_hud_y, L_HUD_R, L_HUD_G, L_HUD_B
new d_hud_x, D_HUD_R, D_HUD_G, D_HUD_B
new dmg_mode[33]
new top1[32], top2[32], top3[32]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("Damage", "Damage_Event", "b", "2!0", "3=0", "4!0")

	l_hud_x = register_cvar("list_hud_x", "0.8")
	l_hud_y = register_cvar("list_hud_y", "0.3")
	/*Above is about the top3 list's x-axis and y-axis.*/

	L_HUD_R = register_cvar("list_hud_r", "85")
	L_HUD_G = register_cvar("list_hud_g", "152")
	L_HUD_B = register_cvar("list_hud_b", "173")
	/*Above is about the top3 list's color with HUD form.*/

	d_hud_x = register_cvar("dmg_hud_x", "-0.52")

	g_Sync= CreateHudSyncObj(8)
	g_MaxP = get_maxplayers()

	register_logevent("logevent_round_start",2,"1=Round_Start")
	//set_task(0.5, "set_dmg_list", _, _, _, "b")
}
public Damage_Event(id)
{
	static attacker; attacker = get_user_attacker(id)
	static damage; damage = read_data(2)
	static Float:dmg_take[33]

	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return PLUGIN_HANDLED

	g_damage[attacker] += damage
	dmg_take[attacker] += damage

	if(dmg_mode[attacker] !=  6)
		dmg_mode[attacker]++
	else
		dmg_mode[attacker] = 0

	D_HUD_R = random_num(0, 255)
	D_HUD_G = random_num(0, 255)
	D_HUD_B = random_num(0, 255)

	ShowDirectorMessage(attacker, get_pcvar_float(d_hud_x), 0.4+(0.05*dmg_mode[attacker]), D_HUD_R, D_HUD_G, D_HUD_B, 0, 0.1, 0.1, 1.0, 0.0, "%.1f", dmg_take[attacker])
	//Above is to show the damage dealt by you with HUD. if u dont want this just comma it.
	dmg_take[attacker] -= damage

	return PLUGIN_HANDLED
}
public logevent_round_start()
{
	for(new i = 1 ; i <= g_MaxP+1 ; i++)
	{
		if(is_user_connected(i) && is_user_alive(i))
		{
			g_damage[i] = 0.0

			if(task_exists(i))
				remove_task(i)

			set_task(1.0, "dmg_show_list", i)
		}
	}
	for(new i = 0 ; i <= 2 ; i++)
		g_player_dmg[i] = 0.0

	top1 = "None"
	top2 = "None"
	top3 = "None"
	set_task(0.5, "set_dmg_list", _, _, _, "b")
}
public dmg_show_list(id)
{
	if(!is_user_connected(id))
		return

	set_hudmessage(get_pcvar_num(L_HUD_R), get_pcvar_num(L_HUD_G), get_pcvar_num(L_HUD_B), get_pcvar_float(l_hud_x), get_pcvar_float(l_hud_y), 0, 0.0, 0.12,0.0,0.0,6)
	ShowSyncHudMsg(id,g_Sync, "Damage:^nTop1 : %s^nDMG:%f^nTop2 : %s^nDMG:%f^nTop3 : %s^nDMG:%f",top1,g_player_dmg[0],top2,g_player_dmg[1],top3,g_player_dmg[2])
	set_task(0.1, "dmg_show_list", id)
}
public set_dmg_list()
{
	for(new i = 1 ; i <= g_MaxP; i++)
	{
		if(is_user_connected(i) && g_damage[i] != 0.0)
		{
			/*Check all players' DMG*/
			if (g_damage[i] >= g_player_dmg[0])
			{
				get_user_name(i, top1, 31)
				g_player_dmg[0] = g_damage[i]
			}
			else if (g_damage[i] >= g_player_dmg[1])
			{
				get_user_name(i, top2, 31)
				g_player_dmg[1] = g_damage[i]
			}
			else if (g_damage[i] >= g_player_dmg[2])
			{
				get_user_name(i, top3, 31)
				g_player_dmg[2] = g_damage[i]
			}
			else
				continue
			continue
		}
	}
}
stock ShowDirectorMessage(id, Float:x, Float:y, r, g, b, effect, Float:fadeintime, Float:fadeouttime, Float:holdtime, Float:fxtime, msg[], {Float, Sql, Result, _}:...)
{
	new text[128];
	vformat(text, 127, msg, 13);
	new len = strlen(text);
	if(!len) return;
	if(id)
		message_begin(MSG_ONE_UNRELIABLE, SVC_DIRECTOR, _, id);
	else
		message_begin(MSG_BROADCAST, SVC_DIRECTOR, _, 0);
	
	write_byte(31+len);	// command length
	write_byte(DRC_CMD_MESSAGE);		// command_event
	write_byte(effect);		// effect
	write_byte(b);	// b
	write_byte(g);	// g
	write_byte(r);	// r
	write_byte(0);	// a
	write_long(_:x);		// x
	write_long(_:y);		// y
	write_long(_:fadeintime);		// fade in time
	write_long(_:fadeouttime);		// fade out time
	write_long(_:holdtime);	// hold time
	write_long(_:fxtime);	// [optional] effect time - time the highlight lags behing the leading text in effect 2
	write_string(text);	// string text message
	message_end();
}