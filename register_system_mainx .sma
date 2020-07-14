#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <nvault>

#define PLUGIN "註冊系統/RegisterSystem"
#define VERSION "1.0"
#define AUTHOR "Nailaz"

/*================================註冊、改名、稱號系統==========================================*/
new g_registered[33], g_login[33], g_password[33][256], g_msg[33][256]
new g_msg_index[33]
new g_countdown[33], g_wrong_count[33]
new g_wrong_limit, g_count_down
new g_password_min, g_password_max

new const filename[] = "addons/amxmodx/configs/players_password.ini"
new const msgdata[] = "addons/amxmodx/configs/players_name_msg.ini"
new lineinfo[2048], readdata[2048], txtlen
new Array:a_Files

new logfilename[256]
new logchat[256]
new logrec[256]

//Chat
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_clcmd("say", "clcmd_hooksay")
	register_clcmd("say_team", "clcmd_hooksay")

	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect")

	g_wrong_limit = register_cvar("register_pw_wrong_limit", "5")
	g_count_down = register_cvar("register_time_limit", "180")
	g_password_min = register_cvar("register_password_min", "4")
	g_password_max = register_cvar("register_password_max", "12")

	get_time("d3_data_%m%d.log", logfilename, 255)
	get_time("d3_chat_%m%d.log", logchat, 255)
	get_time("zm_recommended_%m%d.log", logrec, 255)
}

public client_putinserver(id)
{
	g_registered[id] = false
	g_login[id] = false
	set_task(1.0, "check_database", id)
}
public client_disconnect(id)
{
	g_login[id] = false
	g_registered[id] = false
	g_msg[id] = ""
	g_password[id] = ""
	log_player_file(id)
}
public fw_ClientDisconnect(id)
{
	g_login[id] = false
	g_registered[id] = false
	g_msg[id] = ""
	g_password[id] = ""
	log_player_file(id)
}
public log_player_file(id)
{
	new MONTHS[12][] = {"1月","2月","3月","4月","5月","6月","7月","8月","9月","10月","11月","12月"}
	new DAY[31][] = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"} 
	new ns_Hour[3], ns_Minutes[3],ns_Month[3],ns_Day[3],ns_Year[5],ns_second[3], name[32]

	get_time("%H", ns_Hour, 2); get_time("%M", ns_Minutes, 2); get_time("%m", ns_Month, 2)
	get_time("%d", ns_Day, 2); get_time("%Y", ns_Year, 4); get_time("%S", ns_second, 2)
	get_user_name(id, name, 31)

	log_to_file(logfilename, "---%s年--%s--%s日--%s時--%s分--%s秒---", ns_Year, MONTHS[str_to_num(ns_Month) -1], DAY[str_to_num(ns_Day) -1], ns_Hour, ns_Minutes, ns_second)
	log_to_file(logfilename, "玩家名稱: %s ", name)//record player name
	log_to_file(logfilename, "===================================================================")
}
public clcmd_write(id)
{
	client_printc(id, "\g[已將資料寫入伺服器文件]")
	log_player_file(id)
	return PLUGIN_HANDLED
}
public check_database(id)
{
	if(!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_HANDLED

	new fsize = get_files_amount_from_ini(a_Files)
	new name[32], f_name[32], f_password[32]
	get_user_name(id, name, 31)
	g_wrong_count[id] = get_pcvar_num(g_wrong_limit)
	g_countdown[id] = get_pcvar_num(g_count_down)
	new i = -1
	while(i < fsize+1)
	{
		read_file(filename, i, readdata, charsmax(readdata), txtlen)
		parse(readdata, f_name, 31, f_password, 31)
		if(equal(name, f_name))
		{
			g_password[id] = f_password
			g_registered[id] = true
			g_login[id] = false

			for (new k = 0;  k <= 6; k ++)
				client_printc(id, "\g[請輸入你的密碼來登入遊戲]")
			break
		}
		else
		{
			i++
			continue
		}
	}
	if(!g_registered[id])
		g_login[id] = false
	set_task(1.0, "Registered_msg", id)
	set_task(1.0, "DarkScreen_Pre", id)
	set_task(2.0, "get_msg", id)
	return PLUGIN_HANDLED
}
public get_msg(id)
{
	if(!is_user_connected(id) || is_user_bot(id))
		return PLUGIN_HANDLED

	new fsize = get_files_amount_from_ini_2(a_Files)
	new name[32], f_name[32], f_msg[256]
	get_user_name(id, name, 31)
	new i = -1
	while(i < fsize+1)
	{
		read_file(msgdata, i, readdata, charsmax(readdata), txtlen)
		parse(readdata, f_name, 31, f_msg, 255)
		if(equal(name, f_name))
		{
			g_msg[id] = f_msg
			g_msg_index[id] = i
			break
		}
		else
		{
			i++
			continue
		}
	}
	return PLUGIN_HANDLED
}
public Registered_msg(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	if(!g_registered[id])
		for (new k = 0;  k <= 6; k ++)
			client_printc(id, "\g[此名稱未被註冊，請在對話框輸入你想使用的密碼]")
	return PLUGIN_HANDLED
}
public DarkScreen_Pre(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED

	if(!g_countdown[id] && !is_user_bot(id))
		server_cmd("kick #%d ^"你因為沒有在%d秒內登入而被伺服器踢出^"", get_user_userid(id), get_pcvar_num(g_count_down))

	if(!g_registered[id])
	{
		ShowDirectorMessage(id, -1.0, 0.35, 121, 175, 193, 0, 0.8, 0.5, 0.5, 0.0, "— 註冊系統 —^n由於此ID尚未註冊^n請在%d秒內輸入想要的密碼進行註冊^nY鍵直接輸入即可", g_countdown[id])
		dark_effect_and_msg(id)
	}
	else
	{
		if(!g_login[id])
		{
			// client_print(id, print_center, "請在%d秒內輸入密碼登入", g_countdown[id])
			ShowDirectorMessage(id, -1.0, 0.35, 121, 175, 193, 0, 0.8, 0.5, 0.5, 0.0, "— 註冊系統 —^n請在%d秒內輸入密碼來登入^n密碼輸入錯誤次數剩餘:[%d/%d]", g_countdown[id], g_wrong_count[id], get_pcvar_num(g_wrong_limit))
			dark_effect_and_msg(id)
		}
		else
		{
			message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
			write_short((1<<12)) // duration
			write_short(0) // hold time
			write_short(0x0000) // fade type
			write_byte(0) // red
			write_byte(20) // green
			write_byte(20) // blue
			write_byte(100) // alpha
			message_end()
		}
	}
	return PLUGIN_HANDLED
}
public dark_effect_and_msg(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id) 
	write_short(30500)  
	write_short(30500)  
	write_short(1<<12)  
	write_byte(0)  
	write_byte(0)  
	write_byte(0)  
	write_byte(255)  
	message_end()

	// message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	// write_short((1<<12)) // duration
	// write_short(0) // hold time
	// write_short(0x0000) // fade type
	// write_byte(28) // red
	// write_byte(28) // green
	// write_byte(28) // blue
	// write_byte(150) // alpha
	// message_end()

	set_task(1.0, "DarkScreen_Pre", id)
	g_countdown[id]--
	return PLUGIN_HANDLED
}
public clcmd_hooksay(id)
{
	new check_prefix[32]
	read_argv(1, check_prefix, charsmax(check_prefix))

	new said[256], name[32]
	read_args(said, charsmax(said))

	new len = strlen(said)
	remove_quotes(said)
	trim(said)
	get_user_name(id, name, 31)

	if(g_registered[id])
	{
		if(!g_login[id])
		{
			for (new k = 0;  k <= len; k ++)
			{
				if(equal(check_prefix, "", 0) || said[k] == ',' || said[k] == ' ' || said[k] == '!' || said[k] == '@' || said[k] == '#' || said[k] == '$' || said[k] == '&' || said[k] == '*' || said[k] == '(' || said[k] == ')' || said[k] == '%' || said[k] == '<' || said[k] == '>' || said[k] == '_' || said[k] == '+' || said[k] == '-' || said[k] == '/')
				{
					client_printc(id, "\g[請勿輸入包含空格或特殊符號的字元]")
					return PLUGIN_HANDLED
				}
			}
			new i = -1
			new fsize = get_files_amount_from_ini(a_Files)
			while(i < fsize+1)
			{
				new f_name[32], f_password[32]
				read_file(filename, i, readdata, charsmax(readdata), txtlen)
				parse(readdata, f_name, 31, f_password, 31)
				if(equal(name, f_name))
				{
					if(equal(said, f_password))
					{
						client_printc(id, "\g[登入成功]")
						g_login[id] = true
						break
					}
					else
					{
						if(g_wrong_count[id] > 1)
						{
							g_wrong_count[id]--
							client_printc(id, "\g[密碼輸入錯誤，你還有%d次機會]", g_wrong_count[id])
						}
						else
						{
							if(!is_user_bot(id))
								server_cmd("kick #%d ^"密碼輸入錯誤次數超過%d次而被伺服器踢出^"", get_user_userid(id), get_pcvar_num(g_wrong_limit))
						}
					}
					return PLUGIN_HANDLED
				}
				else
				{
					i++
					continue
				}
			}
		}
		else//該ID已註冊且登入了
		{
			if(equal(said, g_password[id]))
			{
				client_printc(id, "\g[請勿將密碼打在對話框]")
				return PLUGIN_HANDLED
			}
			if(equal(check_prefix, " ", 1) || equal(check_prefix, "", 0))
				return PLUGIN_HANDLED

			if(equal(check_prefix, "/msg ", 5))
			{
				if(strlen(said[5]) > 22)
				{
					client_printc(id, "\g[稱號長度不能超過22個字]")
					return PLUGIN_HANDLED
				}
				get_msg(id)
				new msg_buffer[256]
				formatex(msg_buffer, charsmax(msg_buffer), said[5])
				client_printc(id, "\g[你的稱號已改為 \t%s\g]", said[5])
				g_msg[id] = msg_buffer
				formatex(lineinfo, charsmax(lineinfo), "^"%s^" ^"%s^"", name, g_msg[id])
				new fsize = get_files_amount_from_ini_2(a_Files)

				if(g_msg_index[id])
					write_file(msgdata, lineinfo , g_msg_index[id])
				else
					write_file(msgdata, lineinfo , fsize)
				return PLUGIN_HANDLED
			}
			if(equal(check_prefix, "/x ", 3))
			{
				ShowDirectorMessage(id, -1.0, 0.2, 121, 175, 193, 0, 4.0, 0.0, 0.0, 0.0, "%s : %s", name, said[3])
				return PLUGIN_HANDLED
			}
			if(equal(check_prefix, "/rec ", 5))
			{
				client_printc(id, "\g[成功回報: %s]", said[5])
				log_to_file(logrec, "%s : %s", name, said[5])
				return PLUGIN_HANDLED
			}
			new msg_reg[128]
			if(!strlen(g_msg[id]))
				formatex(msg_reg, charsmax(msg_reg), "")
			else
				formatex(msg_reg, charsmax(msg_reg), "[%s]", g_msg[id])

			client_printc(0, "\g%s\t%s \y: \g%s", msg_reg, name, said)
			log_to_file(logchat, "%s%s \y: \g%s", msg_reg, name, said)
			return PLUGIN_HANDLED
		}
	}
	else
	{
		for (new k = 0;  k <= len; k ++)
		{
			if(equal(check_prefix, "", 0) || said[k] == ',' || said[k] == ' ' || said[k] == '!' || said[k] == '@' || said[k] == '#' || said[k] == '$' || said[k] == '&' || said[k] == '*' || said[k] == '(' || said[k] == ')' || said[k] == '%' || said[k] == '<' || said[k] == '>' || said[k] == '_' || said[k] == '+' || said[k] == '-' || said[k] == '/')
			{
				client_printc(id, "\g[請勿使用包含空格或特殊符號的字元當作密碼]")
				return PLUGIN_HANDLED
			}
		}
		if(len < (get_pcvar_num(g_password_min)+2) || len > (get_pcvar_num(g_password_max)+2))
		{
			client_printc(id, "\g[密碼長度請介於%d到%d]", get_pcvar_num(g_password_min), get_pcvar_num(g_password_max))
			return PLUGIN_HANDLED
		}
		g_password[id] = said
		Confirm_passord(id)
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public Confirm_passord(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED

	new szInfo[120]
	formatex(szInfo, 119, "\y是否確認使用以下的密碼?^n\w已輸入的密碼 : \r%s", g_password[id])

	new menu = menu_create(szInfo , "Confirm_passord_case")

	new szTempid[32], szItems[60]

	formatex(szItems, 59, "\y確認")
	num_to_str(1, szTempid, 31)
	menu_additem(menu, szItems, szTempid, 0)

	formatex(szItems, 59, "\d取消")
	num_to_str(2, szTempid, 31)
	menu_additem(menu, szItems, szTempid, 0)

	menu_setprop(menu , MPROP_EXIT , MEXIT_ALL)
	menu_display(id , menu , 0)
	return PLUGIN_HANDLED
}
public Confirm_passord_case(id , menu , item) 
{ 
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu)
		return PLUGIN_HANDLED
	} 
	new data[6], iName[64], access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)

	new i = str_to_num(data)

	if(i == 1)
	{
		new name[32]
		get_user_name(id, name, 31)
		formatex(lineinfo, charsmax(lineinfo), "^"%s^" ^"%s^"", name, g_password[id])
		new fsize = get_files_amount_from_ini(a_Files)
		write_file(filename, lineinfo , fsize)

		for (new k = 0;  k <= 6; k ++)
			client_printc(id, "\g[註冊成功 請牢記你的密碼 : \t%s\g]", g_password[id])

		g_registered[id] = true
		g_login[id] = true
	}
	else
	{
		g_password[id] = ""
		client_printc(id, "\g[已取消此密碼，請重新輸入新的密碼註冊]")
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}
public get_files_amount_from_ini(Array:a_Files)
{
	a_Files = ArrayCreate(1024)
	new s_Buffer[1024]
	new openF = fopen(filename, "rt")
	
	while (!feof(openF))
	{
		fgets(openF, s_Buffer, charsmax(s_Buffer))
		trim(s_Buffer)

		if (!s_Buffer[0] || s_Buffer[0] == ';' || s_Buffer[0] == '[' || (s_Buffer[0] == '/' && s_Buffer[1] == '/'))
			continue

		ArrayPushString(a_Files, s_Buffer)
	}
	fclose(openF)
	return ArraySize(a_Files)
}
public get_files_amount_from_ini_2(Array:a_Files)
{
	a_Files = ArrayCreate(1024)
	new s_Buffer[1024]
	new openF = fopen(msgdata, "rt")
	
	while (!feof(openF))
	{
		fgets(openF, s_Buffer, charsmax(s_Buffer))
		trim(s_Buffer)

		if (!s_Buffer[0] || s_Buffer[0] == ';' || s_Buffer[0] == '[' || (s_Buffer[0] == '/' && s_Buffer[1] == '/'))
			continue

		ArrayPushString(a_Files, s_Buffer)
	}
	fclose(openF)
	return ArraySize(a_Files)
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
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
stock fm_cs_set_user_team(id, team)
{
	set_pdata_int(id, OFFSET_CSTEAMS, team, OFFSET_LINUX)
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