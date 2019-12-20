#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <nvault>

#define PLUGIN "WOD-LevelSystem"
#define VERSION "1.0"
#define AUTHOR "Nailaz"

#define MAX_VAR_EXISTS 30	//To define how much variables can exists.
new g_var[33][MAX_VAR_EXISTS]
new g_checkname[33]
new g_vault

enum
{
	exp = 0,
	total_exp,
	level,
	gold,
	cash,
	spoint,
	online_time,//second
	create_time,//ex: 19990803
	/*You can add more var you need as above.*/
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("set_pt", "clcmd_setpoints")
	register_clcmd("set_lv", "clcmd_setlevel")
	register_clcmd("set_txp", "clcmd_settxp")
	register_clcmd("set_reset", "clcmd_setreset")

	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")

	g_vault = nvault_open("world_of_the_dead_sublevelsystem")
}
/*API*/
public plugin_natives()
{
	register_native("get_user_level", "native_get_user_level", 1)
	register_native("set_user_level", "native_set_user_level", 1)
	register_native("get_user_xp", "native_get_user_xp", 1)
	register_native("set_user_xp", "native_set_user_xp", 1)
	register_native("get_user_pt", "native_get_user_pt", 1)
	register_native("set_user_pt", "native_set_user_pt", 1)
	register_native("get_user_np", "native_get_user_np", 1)
	register_native("set_user_np", "native_set_user_np", 1)
	register_native("get_user_txp", "native_get_user_txp", 1)
	register_native("set_user_txp", "native_set_user_txp", 1)

	register_native("reset_abilities", "reset_abilities_func", 1)
}
public native_get_user_level(id)
	return g_var[id][level]
public native_set_user_level(id, amount)
{
	g_var[id][level] = amount
	check_level_and_exp(id)
	return g_var[id][level]
}
public native_get_user_xp(id)
	return g_var[id][exp]
public native_set_user_xp(id, amount)
{
	g_var[id][exp] = amount
	check_level_and_exp(id)
	return g_var[id][exp]
}
public native_get_user_txp(id)
	return g_var[id][total_exp]
public native_set_user_txp(id, amount)
{
	g_var[id][total_exp] = amount
	return g_var[id][total_exp]
}
public native_get_user_pt(id)
	return g_var[id][spoint]
public native_set_user_pt(id, amount)
{
	g_var[id][spoint] = amount
	return g_var[id][spoint]
}
public native_get_user_cash(id)
	return g_var[id][cash]
public native_set_user_cash(id, amount)
{
	g_var[id][cash] = amount
	return g_var[id][cash]
}
public check_level_and_exp(id)
{
	static exp_needed
	exp_needed = g_var[id][level]*100
	exp_needed *= 1.2
	while(g_var[id][exp] >= exp_needed)
	{
		g_var[id][level]++
		g_var[id][spoint]++
		g_var[id][exp] -= exp_needed
		new name[64]
		get_user_name(id, name, charsmax(name))
		client_printc(0, "\t[Notcie]\g%s's level up (%d)!!!", name, g_var[id][level])
	}
}
/*API*/
public client_putinserver(id)
{
	DATA_load(id)
}
public client_disconnect(id)
{
	DATA_save(id)
}
public fw_ClientDisconnect(id)
{
	DATA_save(id)
}
public client_infochanged(id)
{
	if(g_checkname[id])
		g_checkname[id] = false
	else if (is_user_connected(id))
	{
		new g_oldname[32], g_newname[32]
		get_user_info(id, "name", g_newname, 31)
		get_user_name(id, g_oldname, 31)
		if(!equal(g_oldname, g_newname))
		{
			for (new k = 0;  k <= 2; k ++)
				client_printc(id, "\t[Notice]\gIt's not allowed to change your name in the game.")
			set_user_info(id, "name", g_oldname)
			g_checkname[id] = true
		}
	}
	return PLUGIN_CONTINUE
}
public clcmd_setpoints(id, level, cid)
{
	new name[32]
	get_user_name(id, name, 31)
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Arg1[256], Arg2[30], Target, Num
		new name1[32]
		read_argv(1, Arg1, 255)
		read_argv(2, Arg2, 29)
		Target = cmd_target(id, Arg1, 0)
		Num = str_to_num(Arg2)
		if(Target)
		{
			if(is_user_connected(Target))
			{
				g_var[Target][spoint] = Num
				get_user_name(id, name, 31)
				get_user_name(Target, name1, 31)
				client_printc(0, "\g[Admin %s set %s's Skill point to %d]", name, name1, Num)
			}
		}
	}
	return PLUGIN_HANDLED
}
public clcmd_setlevel(id, level, cid)
{
	new name[32]
	get_user_name(id, name, 31)
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Arg1[256], Arg2[30], Target, Num
		new name1[32]
		read_argv(1, Arg1, 255)
		read_argv(2, Arg2, 29)
		Target = cmd_target(id, Arg1, 0)
		Num = str_to_num(Arg2)
		if(Target)
		{
			if(is_user_connected(Target))
			{
				g_var[Target][level] = Num
				get_user_name(id, name, 31)
				get_user_name(Target, name1, 31)
				client_printc(0, "\g[Admin %s set %s's Level to %d]", name, name1, Num)
			}
		}
	}
	return PLUGIN_HANDLED
}
public clcmd_settxp(id, level, cid)
{
	new name[32]
	get_user_name(id, name, 31)
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Arg1[256], Arg2[30], Target, Num
		new name1[32]
		read_argv(1, Arg1, 255)
		read_argv(2, Arg2, 29)
		Target = cmd_target(id, Arg1, 0)
		Num = str_to_num(Arg2)
		if(Target)
		{
			if(is_user_connected(Target))
			{
				g_var[id][total_exp] = Num
				get_user_name(id, name, 31)
				get_user_name(Target, name1, 31)
				client_printc(0, "\g[Admin %s set %s's Total EXP to %d]", name, name1, Num)
			}
		}
	}
	return PLUGIN_HANDLED
}
public clcmd_setreset(id)
{
	new name[32]
	get_user_name(id, name, 31)
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Arg1[256], Arg2[30], Target
		new name1[32]
		read_argv(1, Arg1, 255)
		read_argv(2, Arg2, 29)
		Target = cmd_target(id, Arg1, 0)
		if(Target)
		{
			if(is_user_connected(Target))
			{
				g_var[Target][exp] = 0
				g_var[Target][total_exp] = 0
				g_var[Target][level] = 0
				g_var[Target][cash] = 0
				g_var[Target][gold] = 0
				get_user_name(id, name, 31)
				get_user_name(Target, name1, 31)
				client_printc(0, "\g[Admin %s has cleaned %s's DATA]", name, name1)
			}
		}
	}
	return PLUGIN_HANDLED
}
public DATA_save(id)
{
	new name[64], vaultdata[512]
	get_user_name(id, name, charsmax(name))

	for(new n = 0; n < MAX_VAR_EXISTS; n++)
		format(vaultdata, charsmax(vaultdata), "%s%i ", vaultdata, g_var[id][n])

	nvault_set(g_vault, name, vaultdata)
	return PLUGIN_CONTINUE
}
public DATA_load(id)
{
	new name[64], vaultdata[512]
	new g_buffer_items[32]

	get_user_name(id, name, charsmax(name))

	for(new n = 0; n < MAX_VAR_EXISTS; n++)
		format(vaultdata, charsmax(vaultdata), "%s%i ", vaultdata, g_var[id][n])

	nvault_get(g_vault, name, vaultdata, charsmax(vaultdata))

	for(new n = 0; n < MAX_VAR_EXISTS; n++)
	{
		parse(vaultdata, g_buffer_items, charsmax(g_buffer_items))
		g_var[id][n] = str_to_num(g_buffer_items)
		replace_all_custom(vaultdata, charsmax(vaultdata), g_buffer_items,  "")
	}
	return PLUGIN_CONTINUE
}
stock replace_all_custom(string[], len, const what[], const with[])
{
	new pos = 0;
	if ((pos = contain(string, what)) == -1)
		return 0;

	new total = 0;
	new with_len = strlen(with);
	new diff = strlen(what) - with_len;
	new total_len = strlen(string);
	new temp_pos = 0;
	
	while (replace(string[pos], len - pos, what, with) != 0)
	{
		if(string[pos] == ' ')/* if the sring is 'space' then jump off */
			break

		total++;
		pos += with_len;
		total_len -= diff;

		if (pos >= total_len)
			break;
		temp_pos = contain(string[pos], what);

		if (temp_pos == -1)
			break;

		pos += temp_pos;
	}
	return total;
}
stock client_printc(const id, const string[], {Float, Sql, Resul,_}:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg, sizeof msg - 1, string, 3);
	
	replace_all(msg,190,"\g","^4");
	replace_all(msg,255,"\y","^1");
	replace_all(msg,190,"\t","^3");
	
	if(id)
		players[0] = id;
	else
		get_players(players,count,"ch");
	
	new index;
	for (new i = 0 ; i < count ; i++)
	{
		index = players[i];
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"),_, index);
		write_byte(index);
		write_string(msg);
		message_end();  
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
