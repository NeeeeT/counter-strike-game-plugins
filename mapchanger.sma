#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <fakemeta>

//每個ini的地圖數量不要少於map_amount_inmenu
#define	map_amount_inmenu		6


#define TASK_TAG			1999
#define TASK_TAG1			2019
#define TASK_VOTEMAPRE		335533

new g_iMsgTeamInfo, g_iMsgSayText
enum Color
{
	NORMAL = 1,
	GREEN,
	RED,
	BLUE,
	GRAY
}
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}
enum
{
	RED = 1,
	BLUE,
	YELLOW,
	GREEN
}
new TeamName[ ][ ] =
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new map_memories, maps_amount, maxqq, map_vote_countdown, map_remaining, map_gaming, rtv_num, map_nextmap_timeleft

new file_mapname_get[map_amount_inmenu+1][32], votes[map_amount_inmenu+1], get_maps_index[map_amount_inmenu+1]

new bool:Has_Chosen_map[33], Has_rtv[33]
new bool:maps_vote_counted_end, change_map

new nextmap[32]
new Array:a_Maps
new g_MaxP
new timess, rtv_total, adm_set_nextmap, voting
new n_time

new const filename[3][] = 
{
	"addons/amxmodx/configs/maps_list.ini",
	"addons/amxmodx/configs/maps_memories.ini",
	"addons/amxmodx/configs/maps_next.ini"
}

new const sound_countdown[10][] = { "fvox/one.wav", "fvox/two.wav", "fvox/three.wav", "fvox/four.wav", "fvox/five.wav", "fvox/six.wav", "fvox/seven.wav", "fvox/eight.wav", "fvox/nine.wav", "fvox/ten.wav" }

public plugin_init()
{
	register_plugin("地圖投票", "1.0", "Nailaz")

	register_clcmd("admin_votemaps", "admin_force_vote")//管理員強制開啟投票指令
	register_clcmd("admin_nextmap", "admin_nextmap")//管理員開啟下張地圖選單
	register_clcmd("admin_vm", "force_changemap")

	register_logevent("logevent_round_start",2,"1=Round_Start")

	g_MaxP = get_maxplayers()
	g_iMsgSayText = get_user_msgid("SayText")
	g_iMsgTeamInfo = get_user_msgid("TeamInfo")

	map_memories		= register_cvar("maps_memories", "6")//記憶多少張玩過的地圖
	map_remaining		= register_cvar("maps_timeleft_vote", "2")//timeleft剩餘多少分鐘後開始進行投票
	map_vote_countdown	= register_cvar("maps_vote_countdown", "15.0")//地圖投票開始多少秒後結束
	map_gaming		= register_cvar("maps_vote_gaming", "4")//地圖開始多少分鐘後才可以投票換地圖
	rtv_num 		= register_cvar("maps_vote_players_rate", "0.55")//地圖需要多少比例的玩家才能發動投票 ex. 15人需要9人rtv
	map_nextmap_timeleft	= register_cvar("maps_nextmap_timeleft", "1")//管理員設置下一張地圖時，timeleft剩多少時更換

	set_task(5.0, "check_time", _, _, _, "b")

	register_clcmd("say rtv", "clcmd_rtv")
	register_clcmd("rtv", "clcmd_rtv")
	register_clcmd("say nextmap", "clcmd_nextmap")
	register_clcmd("say timeleft", "clcmd_timeleft")
}
public check_time()
{
	new minutes
	minutes = get_timeleft() / 60
	if(adm_set_nextmap)
	{
		if((minutes <= get_pcvar_num(map_nextmap_timeleft)) && !change_map)
		{
			//ColorChat(0, GRAY, "[地圖剩餘%d分鐘，將於下回合更換至%s]", get_pcvar_num(map_nextmap_timeleft), nextmap)
			client_printc(0, "\t地圖剩餘%d分鐘，將於下回合更換至%s", get_pcvar_num(map_nextmap_timeleft), nextmap)
			change_map = true
			server_cmd("mp_timelimit 0")
		}
	}
	else
	{
		if((minutes <= get_pcvar_num(map_remaining)) && !voting && !change_map)
		{
			client_printc(0, "\t地圖剩餘%d分鐘，開始進行投票", get_pcvar_num(map_remaining))
			voting = true
			ready_to_maps_vote()
		}
	}
}
public clcmd_nextmap(id)
{
	if(!strlen(nextmap))
		client_printc(id, "\t尚未決定下一張地圖")
	else
		client_printc(0, "\t下一張地圖是 \g%s", nextmap)
}
public clcmd_timeleft(id)
{
	new minutes, seconds
	minutes = get_timeleft() / 60
	seconds = get_timeleft() % 60
	client_printc(0, "\t地圖時間剩餘: %d分%d秒", minutes, seconds)
}
public plugin_precache()
{
	for (new i = 0; i < sizeof sound_countdown; i++)
		engfunc(EngFunc_PrecacheSound, sound_countdown[i])
}
public plugin_cfg()
{
	for(new i = 0; i <= 2; i++)
	{
		if(i == 0)
			write_file(filename[0], "[多功能地圖控制插件] By : Nailaz 此文件為投票地圖列表", 0)
		else if(i == 1)
			write_file(filename[1], "[多功能地圖控制插件] By : Nailaz 此文件紀錄玩過的地圖", 0)
		else if(i == 2)
			write_file(filename[2], "[多功能地圖控制插件] By : Nailaz 此文件記錄管理員選擇下一張地圖列表", 0)
	}
	maps_memorizing()

	maps_amount = get_maps_amount_from_ini(a_Maps, 0)
	if(maps_amount < map_amount_inmenu)
		maxqq = maps_amount
	else
		maxqq= map_amount_inmenu

	return PLUGIN_CONTINUE
}
public logevent_round_start()
{
	if(change_map)
		// server_cmd("changelevel de_dust2x", nextmap)
		server_cmd("changelevel %s", nextmap)
}
public client_disconnected(id)
{
	if(Has_rtv[id])
	{
		rtv_total--
		Has_rtv[id] = false
	}
}
public force_changemap()
{
	set_task(1.0, "ready_to_maps_vote_pre10seconds", TASK_VOTEMAPRE, _, _, "b")
	client_printc(0, "\t管理員開啟地圖投票")
}
public clcmd_rtv(id)
{
	new name[32]
	new minutes = (floatround(get_gametime()) / 60)
	new g_limit = get_pcvar_num(map_gaming)
	if(adm_set_nextmap)
	{
		ColorChat(id, GRAY, "管理員已設置下一張地圖，此功能暫時關閉")
		return PLUGIN_HANDLED
	}
	if(voting)
	{
		ColorChat(id, GRAY, "目前正在進行地圖投票")
		return PLUGIN_HANDLED
	}
	if(change_map)
	{
		ColorChat(id, GRAY, "即將於下回合更換地圖")
		return PLUGIN_HANDLED
	}
	if(minutes >= g_limit)
	{
		if(!Has_rtv[id])
		{
			get_user_name(id, name, 31)
			Has_rtv[id] = true
			rtv_total++
			new k = floatround(get_pcvar_float(rtv_num) * get_playersnum())
			new n = k
			n -= rtv_total
			if(n <= 0 || get_playersnum() == 1)
			{
				client_printc(0, "\trtv人數已足夠，進行地圖投票")
				voting = true
				ready_to_maps_vote()
			}
			else
				client_printc(0, "\t[rtv] \g%s \t發起地圖投票 \g(-%d)", name, n)
		}
		else
			ColorChat(id, GRAY, "你已發起過投票")
	}
	else
		ColorChat(id, GRAY, "至少還必須經過%d分鐘才可以投票", (g_limit - minutes))
	return PLUGIN_HANDLED
}
public admin_force_vote(id)
{
	new name[32]
	get_user_name(id, name, 31)
	if((name[0] == 'N' && name[1] == 'a' && name[2] == 'i' && name[3] == 'l' && name[4] == 'a' && name[5] == 'z') || (get_user_flags(id) & ADMIN_BAN))
	{
		new name[32]
		get_user_name(id, name, 31)
		client_printc(0, "管理員 %s 開啟地圖投票", name)
		voting = true
		ready_to_maps_vote()
	}
	return PLUGIN_HANDLED
}
public admin_nextmap(id)
{
	new name[32]
	get_user_name(id, name, 31)
	if((name[0] == 'N' && name[1] == 'a' && name[2] == 'i' && name[3] == 'l' && name[4] == 'a' && name[5] == 'z') || (get_user_flags(id) & ADMIN_BAN))
		admin_nextmap_menu(id)
	return PLUGIN_HANDLED
}
public ready_to_maps_vote_pre10seconds()
{
	if(timess >= 1 && timess <= 10)
	{
		PlaySound(sound_countdown[timess - 1])
		timess--
	}
	if(timess <= 0)
	{
		ready_to_maps_vote()
		remove_task(TASK_VOTEMAPRE)
	}
}
public ready_to_maps_vote()
{
	new file_mapname_a[32], file_mapname_b[32], readdata[128], txtlen
	new bool:Repeatable = false
	maps_vote_counted_end = false

	for (new i = 1; i < maxqq+1; i++)
	{
		Repeatable = false
		get_maps_index[i] = random_num(1, maps_amount)
		read_file(filename[0], get_maps_index[i], readdata,127, txtlen)
		parse(readdata, file_mapname_a, 31)

		for (new k = 1; k < get_pcvar_num(map_memories)+1; k++)
		{
			read_file(filename[1], k, readdata,127, txtlen)
			parse(readdata, file_mapname_b, 31)

			if(equal(file_mapname_a, file_mapname_b))
			{
				i--
				Repeatable = true
				break
			}
		}
		for (new j = 1; j < i; j++)
		{
			if(Repeatable)
				break
			else
				if(get_maps_index[i] == get_maps_index[j])
					i--
		}
	}
	set_task(get_pcvar_float(map_vote_countdown), "Maps_countdown_end", TASK_TAG1)
	for (new j = 1; j < map_amount_inmenu+1; j++)
		votes[j] = 0
	for (new i = 1; i < maxqq+1; i++)
	{
		read_file(filename[0], get_maps_index[i], readdata,127, txtlen)
		parse(readdata, file_mapname_get[i], 31)
	}
	for (new j = 1; j <= g_MaxP; j++)
		if(is_user_connected(j))
			Has_Chosen_map[j] = false
	n_time = 15
	set_task(1.0, "maps_vote_all", 378974, _, _, "b")
	set_task(0.5, "maps_vote_show", 17589, _, _, "b")
}
public maps_vote(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	if(maps_vote_counted_end)
		return PLUGIN_HANDLED
	if(Has_Chosen_map[id])
		return PLUGIN_HANDLED

	new szInfo[120]
	formatex(szInfo, 119, "投票下一張地圖^n\w時間剩餘 : %d秒", n_time)

	new menu = menu_create(szInfo , "maps_vote_menu_case")
	new szTempid[32], szItems[120]

	for (new i = 1; i < maxqq+1; i++)
	{
		formatex(szItems, 119, "\w%s \y票數 : \r%d", file_mapname_get[i], votes[i])
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	menu_display(id , menu , 0)
	return PLUGIN_HANDLED
}
public maps_vote_all()
{
	if(!voting || maps_vote_counted_end)
		remove_task(378974)
	n_time--
}
public maps_vote_show()
{
	if(!voting || maps_vote_counted_end)
		remove_task(17589)
	for (new j = 1; j <= g_MaxP; j++)
	{
		if(is_user_connected(j) && !Has_Chosen_map[j])
			maps_vote(j)
	}
}
public maps_vote_menu_case(id , menu , item)
{
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} 
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	new i = str_to_num(data)

	for (new j = 1; j < map_amount_inmenu+1; j++)
	{
		if(i == j)
		{
			if(!Has_Chosen_map[id])
			{
				votes[i]++
				Has_Chosen_map[id]  = true
			}
		}
	}
	return PLUGIN_HANDLED
}
public Maps_countdown_end()
{
	if(task_exists(TASK_TAG1))
		remove_task(TASK_TAG1)

	maps_vote_counted_end = true
	new x = 0, count = 0, nMaps[map_amount_inmenu+1][32]

	for (new i = 1; i < map_amount_inmenu+1; i++)/*取得最大投票數*/
		if(votes[i] >= x)
			x = votes[i]
	for (new j = 1; j < map_amount_inmenu+1; j++)/*取得重複票數的地圖*/
	{
		if(votes[j] == x)
		{
			count++
			nMaps[count] = file_mapname_get[j]
		}
	}
	new r = random_num(1, count)
	nextmap = nMaps[r]
	client_printc(0, "\t投票結束，下一張地圖是 \g%s",nextmap)
	client_printc(0, "\t地圖將在下一回合更換")
	voting = false
	change_map = true
	server_cmd("mp_timelimit 0")
}
public ShowMapList(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED

	new mapname[32]
	get_mapname(mapname,31)
	new szInfo[120]
	formatex(szInfo, 119, "查看目前可提名和投票的地圖^n\d當前地圖:%s^n", mapname)

	new menu = menu_create(szInfo , "ShowMapList_case")
	new szTempid[32], szItems[120]

	new maps_amounts, file_mapname[32]

	maps_amounts = get_maps_amount_from_ini(a_Maps, 0)

	for (new i = 1; i < maps_amounts+1; i++)
	{
		new readdata[128], txtlen; read_file(filename[0], i, readdata,127, txtlen); parse(readdata, file_mapname, 31)

		formatex(szItems, 119, "\w%s", file_mapname)
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}

	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	menu_display(id , menu , 0)
	return PLUGIN_HANDLED
}
public ShowMapList_case(id , menu , item)
{
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} 
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	new i = str_to_num(data)
	new maps_amount = get_maps_amount_from_ini(a_Maps, 0)

	for (new j = 1; j < maps_amount+1; j++)
	{
		if(i == j)
			ShowMapList(id)
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public admin_nextmap_menu(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED

	new mapname[32]
	get_mapname(mapname,31)
	new szInfo[120]
	formatex(szInfo, 119, "\y設置下一張地圖為:%s^n\w選擇後即不會開啟地圖投票^nrtv功能也將暫時關閉^n\d", nextmap)

	new menu = menu_create(szInfo , "admin_nextmap_menu_case")
	new szTempid[32], szItems[120]

	new maps_amounts, file_mapname[32]

	maps_amounts = get_maps_amount_from_ini(a_Maps, 2)

	for (new i = 1; i < maps_amounts+1; i++)
	{
		new readdata[128], txtlen; read_file(filename[2], i, readdata,127, txtlen); parse(readdata, file_mapname, 31)
		if(equal(file_mapname, nextmap))
		{
			formatex(szItems, 119, "\w%s\y[下張地圖]", file_mapname)
			num_to_str(i, szTempid, 31)
			menu_additem(menu, szItems, szTempid, 0)
		}
		else if(equal(file_mapname, mapname))
		{
			formatex(szItems, 119, "\w%s\y[當前地圖]", file_mapname)
			num_to_str(i, szTempid, 31)
			menu_additem(menu, szItems, szTempid, 0)
		}
		else
		{
			formatex(szItems, 119, "\w%s", file_mapname)
			num_to_str(i, szTempid, 31)
			menu_additem(menu, szItems, szTempid, 0)
		}
	}
	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	menu_display(id , menu , 0)
	return PLUGIN_HANDLED
}
public admin_nextmap_menu_case(id , menu , item)
{
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} 
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	new i = str_to_num(data)
	new maps_amount = get_maps_amount_from_ini(a_Maps, 2)

	for (new j = 1; j < maps_amount+1; j++)
	{
		if(i == j)
		{
			new readdata[128], txtlen, nextmapname[32]
			read_file(filename[2], i, readdata,127, txtlen)
			parse(readdata, nextmapname, 31)
			nextmap  = nextmapname
			adm_set_nextmap = true
			client_printc(0, "\t管理員設置下一張地圖為 \g%s \t將於地圖時間剩餘%d分鐘時更換", nextmap, get_pcvar_num(map_nextmap_timeleft))
			admin_nextmap_menu(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public maps_memorizing()
{
	new mapname[32]
	get_mapname(mapname,31)

	new iFileHandle = fopen(filename[1], "rt")
	new szLineItem[64], lineinfo[256]
	new bool:Repeatable = false
	new bool:Has_written = false

	fgets(iFileHandle, szLineItem , charsmax(szLineItem))
	formatex(lineinfo, charsmax(lineinfo), "%s", mapname)

	for (new i = 1; i < get_pcvar_num(map_memories)+1; i++)
	{
		new readdata[128], file_mapname[32], txtlen; read_file(filename[1], i, readdata,127, txtlen); parse(readdata, file_mapname, 31)

		if(equal(mapname, file_mapname))
			Repeatable = true
	}
	if(!Repeatable)
	{
		for (new line = 1; line < get_pcvar_num(map_memories)+1; line++)
		{
			new readdata[128], file_mapname[32], txtlen; read_file(filename[1], line, readdata,127, txtlen); parse(readdata, file_mapname, 31)

			if(!file_mapname[0] || file_mapname[0] == ';')
			{
				write_file(filename[1] , lineinfo , line)
				Has_written = true
				break
			}
			else
				continue
		}
		if(!Has_written)
		{
			for (new k = 2; k < get_pcvar_num(map_memories)+1 ; k++)
			{
				new readdata[128], file_mapname[32], txtlen; read_file(filename[1], k, readdata,127, txtlen); parse(readdata, file_mapname, 31)
				write_file(filename[1] , file_mapname , k-1)
			}
			write_file(filename[1] , lineinfo , get_pcvar_num(map_memories))
		}
	}
}
public get_maps_amount_from_ini(Array:a_Mapss, num)
{
	a_Mapss = ArrayCreate(128)
	new s_Buffer[128]
	new openF = fopen(filename[num], "rt")
	
	while (!feof(openF))
	{
		fgets(openF, s_Buffer, charsmax(s_Buffer))
		trim(s_Buffer)

		if (!s_Buffer[0] || s_Buffer[0] == ';' || (s_Buffer[0] == '/' && s_Buffer[1] == '/'))
			continue

		if (is_map_valid(s_Buffer))
			ArrayPushString(a_Mapss, s_Buffer)
	}
	return ArraySize(a_Mapss)
}
//colorchat
ColorChat(id, Color:type, const szMessage[], {Float,Sql,Result,_}:... )
{
	if(!get_playersnum()) return
	
	new message[256]
	
	switch(type)
	{
		case NORMAL: message[0] = 0x01
		case GREEN: message[0] = 0x04
		default: message[0] = 0x03
	}
	vformat( message[1], 251, szMessage, 4)
	
	message[ 192 ] = '^0'
	
	replace_all( message, 191, "\YEL", "^1" )
	replace_all( message, 191, "\GRN", "^4" )
	replace_all( message, 191, "\TEM", "^3" )
	
	new iTeam, ColorChange, index, MSG_Type
	
	if(id)
	{
		MSG_Type = MSG_ONE_UNRELIABLE
		index = id
	}else
	{
		index = CC_FindPlayer()
		MSG_Type = MSG_BROADCAST
	}
	
	iTeam = get_user_team(index)
	ColorChange = CC_ColorSelection(index, MSG_Type, type)

	CC_ShowColorMessage(index, MSG_Type, message)
	
	if(ColorChange)
		CC_Team_Info(index, MSG_Type, TeamName[iTeam])
}
CC_ShowColorMessage(id, type, message[])
{
	message_begin(type, g_iMsgSayText, _, id)
	write_byte(id)
	write_string(message)
	message_end()
}
CC_Team_Info(id, type, team[])
{
	message_begin(type, g_iMsgTeamInfo, _, id)
	write_byte(id)
	write_string(team)
	message_end()
	
	return 1
}
CC_ColorSelection(index, type, Color:Type)
{
	switch(Type) 
	{
		case RED: return CC_Team_Info(index, type, TeamName[1])
		case BLUE: return CC_Team_Info(index, type, TeamName[2])
		case GRAY: return CC_Team_Info(index, type, TeamName[3])
	}
	return 0
}
CC_FindPlayer()
{
	for(new i = 1;i <= get_maxplayers(); i++)
		if(is_user_connected(i))
			return i
	return -1
}
//colorchat
PlaySound(const sound[])
{
	client_cmd(0, "spk ^"%s^"", sound)
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