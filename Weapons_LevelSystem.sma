#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <nvault>

#define PLUGIN "Weapons Level System"
#define VERSION "1.0"
#define AUTHOR "Nailaz"

#define MAX_WPS_NUM 26
#define TASK_SAVEx 2019
#define ID_SAVEx (taskid - TASK_SAVEx)

new g_wps_level[33][MAX_WPS_NUM], g_wps_exp[33][MAX_WPS_NUM]
new g_current_wps_id[33]
new Float:g_damage[33], g_vault, huding[33]

new const g_weapons_name[MAX_WPS_NUM][] = 
{
	"",
	"1",//CSW_P228
	"3",//CSW_SCOUT
	"5",//CSW_XM1014
	"7",//CSW_MAC10
	"8",//CSW_AUG
	"10",//CSW_ELITE
	"11",//CSW_FIVESEVEN
	"12",//CSW_UMP45
	"13",//CSW_SG550
	"14",//CSW_GALIL
	"15",//CSW_FAMAS
	"16",//CSW_USP
	"17",//CSW_GLOCK18
	"18",//CSW_AWP
	"19",//CSW_MP5NAVY
	"20",//CSW_M249
	"21",//CSW_M3
	"22",//CSW_M4A1
	"23",//CSW_TMP
	"24",//CSW_G3SG1
	"26",//CSW_DEAGLE
	"27",//CSW_SG552
	"28",//CSW_AK47
	"29",//CSW_KNIFE
	"30"//CSW_P90
}
new const g_weapons_real_name[MAX_WPS_NUM][] = 
{
	"",
	"P228",
	"Scout",
	"Xm1014",
	"Mac10",
	"Aug",
	"Dual Elie",
	"FIveSeven",
	"Ump45",
	"SG550",
	"Galil",
	"Famas",
	"Usp 45",
	"Glock 18",
	"Awp",
	"Mp5",
	"M249",
	"M3",
	"M4A1",
	"Tmp",
	"G3SG1",
	"Deagle",
	"SG552",
	"AK47",
	"刀",
	"P90"
}
new const g_weapons_exp[MAX_WPS_NUM][] = 
{
	"",
	"20",//CSW_P228
	"25",//CSW_SCOUT
	"75",//CSW_XM1014
	"100",//CSW_MAC10
	"100",//CSW_AUG
	"25",//CSW_ELITE
	"25",//CSW_FIVESEVEN
	"100",//CSW_UMP45
	"75",//CSW_SG550
	"100",//CSW_GALIL
	"100",//CSW_FAMAS
	"25",//CSW_USP
	"25",//CSW_GLOCK18
	"50",//CSW_AWP
	"100",//CSW_MP5NAVY
	"125",//CSW_M249
	"75",//CSW_M3
	"100",//CSW_M4A1
	"100",//CSW_TMP
	"75",//CSW_G3SG1
	"25",//CSW_DEAGLE
	"100",//CSW_SG552
	"100",//CSW_AK47
	"50",//CSW_KNIFE
	"100"//CSW_P90
}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	RegisterHam(Ham_Player_PreThink, "player", "fw_PlayerPreThink")

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("Damage", "Damage_Event", "b", "2!0", "3=0", "4!0")
	register_clcmd("set_gunxp", "clcmd_setgxp")
	register_clcmd("say wpsinfo", "clcmd_wpsinfo")
}
public plugin_precache()
	g_vault = nvault_open("Weapons_level")
public plugin_natives()
{
	register_native("get_user_wdmg", "native_get_user_dmg", 1)
	register_native("set_user_wdmg", "native_set_user_dmg", 1)
	register_native("get_user_wlevel", "native_get_user_wps_level", 1)
	register_native("set_user_wpexp", "native_set_user_wpexp", 1)
	register_native("get_user_wpexp", "native_get_user_wpexp", 1)
	register_native("show_wpsinfo", "clcmd_wpsinfo", 1)
}
public native_get_user_dmg(id)
	return floatround(g_damage[id])
public native_set_user_dmg(id, Float:amount)
{
	g_damage[id] = amount
	return floatround(g_damage[id])
}
public native_get_user_wps_level(id)
{
	new n = g_current_wps_id[id]
	return g_wps_level[id][n]
}
public native_set_user_wpexp(id, n, amount)
{
	g_wps_exp[id][n] = amount
	return g_wps_exp[id][n]
}
public native_get_user_wpexp(id, n)
{
	return g_wps_exp[id][n]
}
public client_connect(id)
	fileread_b(id)
public client_putinserver(id)
{
	fileread_b(id)
	set_task(3.0, "Check_datasave_b", id+TASK_SAVEx, _, _, "b")
}
public client_disconnect(id)
{
	filewrite_b(id)
	remove_task(id+TASK_SAVEx)
}
public Check_datasave_b(taskid)
{
	static id
	id = ID_SAVEx
	if(!is_user_connected(id) || is_user_bot(id))
		remove_task(id+TASK_SAVEx)
	filewrite_b(id)
}
public clcmd_setgxp(id, level, cid)
{
	new name[32]
	get_user_name(id, name, 31)
	if((get_user_flags(id) & ADMIN_CHAT))
	{
		new Arg1[256], Arg2[30], Target, Num
		read_argv(1, Arg1, 255)
		read_argv(2, Arg2, 29)
		Target = cmd_target(id, Arg1, 0)
		Num = str_to_num(Arg2)
		if(Target)
		{
			if(is_user_connected(Target))
			{
				g_wps_level[Target][g_current_wps_id[Target]] = Num 
			}
		}
	}
	return PLUGIN_HANDLED
}
public Damage_Event(id)
{
	static attacker; attacker = get_user_attacker(id)
	static damage; damage = read_data(2)
	static victim; victim = read_data(0)

	if(attacker == victim || !is_user_connected(attacker) || !is_user_connected(victim))
		return
	if(attacker == victim || !is_user_alive(attacker) || !is_user_alive(victim))
		return

	g_damage[attacker] += damage
}
public Event_CurWeapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return
	new found = false
	for(new i = 1; i < MAX_WPS_NUM; i++)
	{
		if(get_user_weapon(id) == str_to_num(g_weapons_name[i]))
		{
			g_current_wps_id[id] = i
			found = true
		}
	}
	if(!found)
		g_current_wps_id[id] = 0
	else
		if(!huding[id])
			show_hud_weapons(id)
}
public fw_PlayerPreThink(id) 
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	new n = g_current_wps_id[id]

	if(!g_wps_level[id][n])
	{
		g_wps_level[id][n] = 1
		g_wps_exp[id][n] = 0
		return PLUGIN_HANDLED
	}
	if(n == 0)
		return PLUGIN_HANDLED

	if(g_damage[id] >= 1500.0)
	{
		g_damage[id] -= 1500.0
		g_wps_exp[id][n]++
	}
	new x = str_to_num(g_weapons_exp[n])*g_wps_level[id][n]
	if (g_wps_exp[id][n] >= x)
	{
		g_wps_level[id][n]++
		g_wps_exp[id][n] -=  x
		new name[32]
		get_user_name(id, name, 31)
		client_printc(0, "\g[%s 的 %s 等級上升至 %d]", name, g_weapons_real_name[n], g_wps_level[id][n])
	}
	return PLUGIN_HANDLED
}
public clcmd_wpsinfo(id)
{
	new szInfo[60]
	formatex(szInfo, 59, "\y查看所有武器資訊")

	new menu = menu_create(szInfo , "clcmd_wpsinfo_case")

	new szTempid[32], szItems[60]
	for (new i = 1; i < MAX_WPS_NUM; i++)
	{
		new x = str_to_num(g_weapons_exp[i])*g_wps_level[id][i]
		formatex(szItems, 59, "\w%s \y等級: %d \r經驗值: %d/%d", g_weapons_real_name[i], g_wps_level[id][i], g_wps_exp[id][i], x)
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	menu_display(id , menu , 0)
	return PLUGIN_HANDLED
}
public clcmd_wpsinfo_case(id , menu , item) 
{ 
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} 
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	clcmd_wpsinfo(id)

	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public show_hud_weapons(id)
{
	if(!g_current_wps_id[id] || !is_user_alive(id) || !is_user_connected(id))
	{
		huding[id] = false
		return PLUGIN_HANDLED
	}
	new n = g_current_wps_id[id]
	new x = str_to_num(g_weapons_exp[n])*g_wps_level[id][n]
	new Float:y = g_wps_level[id][n]*2.0
	set_hudmessage(110, 110, 150, 0.65555, 0.8, 0, 6.0, 1.1, 0.1, 0.1, -1)
	show_hudmessage(id, "Weapons: %s | Level: %d | Exp: %d/%d | Damage +%.1f％", g_weapons_real_name[n], g_wps_level[id][n], g_wps_exp[id][n], x, y)
	huding[id] = true
	set_task(1.2, "show_hud_weapons", id)
	return PLUGIN_HANDLED
}
public clcmd_getgxp(id)
	g_wps_exp[id][g_current_wps_id[id]] += 1000
public filewrite_b(id)
{
	new name[64], vaultdata[512]
	get_user_name(id, name, charsmax(name))

	for(new n = 1; n < MAX_WPS_NUM; n++)
		format(vaultdata, charsmax(vaultdata), "%s%i %i ", vaultdata, g_wps_level[id][n], g_wps_exp[id][n])

	nvault_set(g_vault, name, vaultdata)
	return PLUGIN_CONTINUE
}
public fileread_b(id)
{
	new name[64], vaultdata[512]
	new g_buffers[32]

	get_user_name(id, name, charsmax(name))

	for(new n = 1; n < MAX_WPS_NUM; n++)
		format(vaultdata, charsmax(vaultdata), "%s%i %i ", vaultdata, g_wps_level[id][n], g_wps_exp[id][n])

	nvault_get(g_vault, name, vaultdata, charsmax(vaultdata))

	for(new n = 1; n < MAX_WPS_NUM; n++)
	{
		parse(vaultdata, g_buffers, charsmax(g_buffers))
		g_wps_level[id][n] = str_to_num(g_buffers)
		replace_all_custom(vaultdata, charsmax(vaultdata), g_buffers,  "")

		parse(vaultdata, g_buffers, charsmax(g_buffers))
		g_wps_exp[id][n] = str_to_num(g_buffers)
		replace_all_custom(vaultdata, charsmax(vaultdata), g_buffers,  "")
	}
	return PLUGIN_CONTINUE
}
stock replace_all_custom(string[], len, const what[], const with[])
{
	new pos = 0
	if ((pos = contain(string, what)) == -1)
		return 0

	new total = 0
	new with_len = strlen(with)
	new diff = strlen(what) - with_len
	new total_len = strlen(string)
	new temp_pos = 0
	
	while (replace(string[pos], len - pos, what, with) != 0)
	{
		if(string[pos] == ' ')/* if the sring is a space then jump off the loop*/
			break

		total++
		pos += with_len
		total_len -= diff

		if (pos >= total_len)
			break
		temp_pos = contain(string[pos], what)

		if (temp_pos == -1)
			break;

		pos += temp_pos
	}
	return total
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
