#include <clientprefs>
#include <maoling>
#include <cg_core>
#include <store>
#include <smjansson>

//#define USE_SteamWorks

#if defined USE_SteamWorks
	#include <SteamWorks>
#else
	#include <system2>
#endif

#pragma newdecls required

#define PREFIX "[\x10Music\x01]  "
#define SEARCH "https://csgogamers.com/musicserver/api/search.php?s="
#define LYRICS "https://csgogamers.com/musicserver/api/getlrc.php?id="
#define CACHED "https://music.csgogamers.com/api/cached.php?id="
#define PLAYER "https://music.csgogamers.com/api/player.php?id="
#define logFile "addons/sourcemod/logs/musicplayer.log"

float g_fNextPlay;

bool g_bDiable[MAXPLAYERS+1];
bool g_bBanned[MAXPLAYERS+1];
bool g_bListen[MAXPLAYERS+1];
bool g_bInRadio[MAXPLAYERS+1];
bool g_bPause[MAXPLAYERS+1];
int g_iVolume[MAXPLAYERS+1];

enum songinfo
{
	iSongId,
	String:szName[128],
	Float:fLength,
	String:szLen[16]
}

songinfo g_Sound[songinfo];

Handle g_cDisable;
Handle g_cVolume;
Handle g_cBanned;
Handle g_hMainMenu;
Handle g_hVolMenu;
Handle g_hPlayMenu;
Handle array_timer;
Handle array_lyric;

public Plugin myinfo = 
{
	name		= "Media System",
	author		= "Kyle",
	description = "Media System , Powered by CG Community",
	version		= "1.0",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	g_cDisable 	= RegClientCookie("media_disable",	"", CookieAccess_Private);
	g_cVolume	= RegClientCookie("media_volume",	"", CookieAccess_Private);
	g_cBanned 	= RegClientCookie("media_banned", 	"", CookieAccess_Private);

	RegConsoleCmd("sm_music",		Command_Music);
	RegConsoleCmd("sm_dj", 			Command_Music);
	RegConsoleCmd("sm_radio",		Command_Radio);

	RegAdminCmd("sm_adminmusicstop",	Command_AdminStop, ADMFLAG_BAN);
	RegAdminCmd("sm_musicban", 			Command_MusicBan,  ADMFLAG_BAN);
	
	PrepareGlobalMenu();
	
	array_timer = CreateArray();
	array_lyric = CreateArray(ByteCountToCells(128));

	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
		{
			OnClientConnected(client);
			if(AreClientCookiesCached(client))
				OnClientCookiesCached(client);
		}
}

void PrepareGlobalMenu()
{
	//Main Menu
	g_hMainMenu = CreateMenu(MenuHanlder_Main);
	SetMenuTitle(g_hMainMenu, "[多媒体点歌系统] 主菜单");
	AddMenuItem(g_hMainMenu, "musictoall", "点播歌曲给全部人");
	AddMenuItem(g_hMainMenu, "bgmstop", "停止地图音乐");
	AddMenuItem(g_hMainMenu, "musicradio", "聆听音乐电台");
	AddMenuItem(g_hMainMenu, "musicvol", "调节音量(下首歌生效)");
	AddMenuItem(g_hMainMenu, "musicstop", "停止播放音乐");
	AddMenuItem(g_hMainMenu, "musictoggle", "开关接收点歌");
	SetMenuExitButton(g_hMainMenu, true);

	//VolumeMenu
	g_hVolMenu = CreateMenu(MenuHanlder_SelectVolume);
	SetMenuTitle(g_hVolMenu, "[多媒体点歌系统]  音量调整");
	AddMenuItem(g_hVolMenu, "99", "99%音量");
	AddMenuItem(g_hVolMenu, "90", "90%音量");
	AddMenuItem(g_hVolMenu, "80", "80%音量");
	AddMenuItem(g_hVolMenu, "70", "70%音量");
	AddMenuItem(g_hVolMenu, "60", "60%音量");
	AddMenuItem(g_hVolMenu, "50", "50%音量");
	AddMenuItem(g_hVolMenu, "40", "40%音量");
	AddMenuItem(g_hVolMenu, "30", "30%音量");
	AddMenuItem(g_hVolMenu, "20", "20%音量");
	AddMenuItem(g_hVolMenu, "10", "10%音量");
	SetMenuExitBackButton(g_hVolMenu, true);
	SetMenuExitButton(g_hVolMenu, true);
	
	//Player Menu
	g_hPlayMenu = INVALID_HANDLE;
}

public void OnMapEnd()
{
	g_fNextPlay = 0.0;
	ClearArray(array_timer);
	ClearArray(array_lyric);
}

public void OnClientConnected(int client)
{
	g_bPause[client] = false;
	g_bDiable[client] = false;
	g_iVolume[client] = 80;
	g_bBanned[client] = false;
	g_bListen[client] = false;
	g_bInRadio[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char buf[3][4];
	GetClientCookie(client, g_cDisable, buf[0], 4);
	GetClientCookie(client,  g_cVolume, buf[1], 4);
	GetClientCookie(client,  g_cBanned, buf[2], 4);

	g_bDiable[client] = (StringToInt(buf[0]) ==  1);
	g_iVolume[client] = (StringToInt(buf[1]) >= 10) ? StringToInt(buf[1]) : 50;
	g_bBanned[client] = (StringToInt(buf[2]) ==  1);
}

public int MenuHanlder_SelectVolume(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, 64);
		int num = StringToInt(info);
		g_iVolume[client] = num;
		SetClientCookie(client, g_cVolume, info);
		PrintToChat(client, "%s  你的音量已经设置为\x04%s%%", PREFIX, info);
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
			DisplayMenu(g_hMainMenu, client, 0);
	}
}

public int MenuHanlder_Main(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		char info[256];
		GetMenuItem(menu, itemNum, info, 256);
		if(strcmp(info, "musictoggle") == 0)
		{
			g_bDiable[client] = !g_bDiable[client];
			SetClientCookie(client, g_cDisable, g_bDiable[client] ? "1" : "0");
			PrintToChat(client, "%s  \x10点歌接收已%s", PREFIX, g_bDiable[client] ? "\x07关闭" : "\x04开启");
		}
		else if(!strcmp(info, "musicvol"))
			DisplayMenu(g_hVolMenu, client, 0);
		else if(!strcmp(info, "musicradio"))
			Command_Radio(client, 0);
		else if(!strcmp(info, "musicstop"))
			ConfirmStopMenu(client);
		else if(!strcmp(info, "mainmenu"))
			DisplayMenu(g_hMainMenu, client, 0);
		else if(!strcmp(info, "bgmstop"))
		{
			if(FindPluginByFile("KZTimer.smx"))
				FakeClientCommandEx(client, "sm_stopsound");
			else
				FakeClientCommandEx(client, "sm_stop");
		}
		else if(!strcmp(info, "musictoall"))
		{
			if(g_bBanned[client])
			{
				PrintToChat(client, "%s  \x10你点歌权限被BAN了", PREFIX);
				return;
			}

			if(GetGameTime() < g_fNextPlay)
			{
				PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);
				return;
			}

			g_bListen[client] = true;
			PrintToChat(client, "%s  按Y输入 歌名( - 歌手) [小括号内选填]", PREFIX);
		}
	}
}

public int MenuHanlder_PlayPanel(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, 64);
		if(strcmp(info, "musicstop") == 0)
			ConfirmStopMenu(client);
		else if(strcmp(info, "bgmstop") == 0)
		{
			if(FindPluginByFile("KZTimer.smx"))
				FakeClientCommandEx(client, "sm_stopsound");
			else
				FakeClientCommandEx(client, "sm_stop");
		}
	}
}

public int MenuHandler_ConfirmStop(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		if(strcmp(info,"tr") == 0) 
		{
			CG_RemoveMotd(client);
			g_bInRadio[client] = false;
			g_bPause[client] = true;
			UTIL_ClearLyric(client);
			PrintToChat(client, "%s  \x04音乐已停止播放", PREFIX)
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
			DisplayMenu(g_hMainMenu, client, 0);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Action Command_Music(int client, int args)
{
	DisplayMenu(g_hMainMenu, client, 0);
	return Plugin_Handled;
}

public Action Command_Radio(int client, int args)
{
	char url[192];
	Format(url, 192, "https://csgogamers.com/music/index.php?volume=%.2f", g_iVolume[client]*0.01+0.01);
	CG_ShowHiddenMotd(client, url);
	if(!g_bInRadio[client])
	{
		PrintToChat(client, "%s  欢迎收听CG电台(!radio切歌)", PREFIX);
		PrintToChatAll("%s  \x04%N\x01正在收听CG电台(!radio收听)", PREFIX, client);
	}
	UTIL_StopBGM(client);
	g_bInRadio[client] = true;
	return Plugin_Handled;
}

public Action Command_AdminStop(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			CG_RemoveMotd(i);

	g_fNextPlay = 0.0;
	PrintToChatAll("%s \x02权限X强行停止了音乐播放!", PREFIX);
	
	while(GetArraySize(array_timer))
	{
		Handle timer = GetArrayCell(array_timer, 0);
		KillTimer(timer);
		RemoveFromArray(array_timer, 0);
	}

	UTIL_LyricHud(">>> 歌曲已停止播放 <<<");
}

public Action Command_MusicBan(int client, int args)
{
	if(args < 1)
		return Plugin_Handled;

	char buffer[16];
	GetCmdArg(1, buffer, 16);
	int target = FindTarget(client, buffer, true);

	if(!IsValidClient(target))
		return Plugin_Handled;

	g_bBanned[target] = !g_bBanned[target];
	SetClientCookie(target, g_cBanned, g_bBanned[target] ? "1" : "0");
	PrintToChatAll("%s \x02%N\x01%s", PREFIX, target, g_bBanned[target] ? "因为乱玩点歌系统,已被\x07封禁\x01点歌权限" : "点歌权限已被\x04解禁");

	return Plugin_Handled;
}

void ConfirmStopMenu(int client)
{
	Handle menu = CreateMenu(MenuHandler_ConfirmStop);
	SetMenuTitleEx(menu, "[多媒体点歌系统]  你确认要停止播放吗");
	int rdm = GetRandomInt(0, 5);
	for(int x; x <= 5; ++x)
	{
		if(x == rdm)
			AddMenuItem(menu, "tr", "确定");
		else
			AddMenuItem(menu, "no", "拒绝");
	}

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!client || !g_bListen[client])
		return Plugin_Continue;
	
	g_bListen[client] = false;

	if(g_bBanned[client])
	{
		PrintToChat(client, "%s  \x07你已被封禁点歌", PREFIX);
		return Plugin_Continue;
	}
	
	if(GetGameTime() < g_fNextPlay)
	{
		PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);
		return Plugin_Continue;
	}
	
	int cost = 200;
	if(FindPluginByFile("zombiereloaded.smx")) cost = 1000;
	if(Store_GetClientCredits(client) < cost)
	{
		PrintToChat(client, "%s  \x07你的信用点不足!", PREFIX);
		return Plugin_Continue;
	}

	PrintToChat(client, "%s  \x04正在搜索音乐(当前选择引擎: 网易云音乐)", PREFIX);
	
	char url[256];
	Format(url, 256, "%s%s", SEARCH, sArgs)
	ReplaceString(url, 256, " ", "+", false);

#if defined USE_SteamWorks
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(client));
	SteamWorks_SetHTTPCallbacks(hRequest, API_SearchMusic);
	SteamWorks_SendHTTPRequest(hRequest);
#else
	System2_GetPage(API_SearchMusic, url, "", "", GetClientUserId(client));
#endif

	return Plugin_Stop;
}

#if defined USE_SteamWorks
public int API_SearchMusic(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
	if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, API_SearchResult, GetClientOfUserId(userid));
	else
		LogError("SteamWorks -> API_SearchMusic -> HTTP Response failed: %d", eStatusCode);

	CloseHandle(hRequest);
}

public int API_SearchResult(const char[] sData, int client)
{
	UTIL_ProcessResult(sData, strlen(sData), client);
}
#else
public void API_SearchMusic(const char[] output, const int size, CMDReturn status, int userid)
{
	switch(status)
	{
		case CMD_SUCCESS: UTIL_ProcessResult(output, size, GetClientOfUserId(userid))
		case CMD_ERROR  : LogError("System2 -> API_SearchMusic -> HTTP Response failed: %s", output);
	}
}
#endif

void UTIL_ProcessResult(const char[] sData, int maxLen, int client)
{
	if(!IsValidClient(client) || !maxLen)
		return;

	JSONValue hObj = json_load(sData);
	KeyValues Response = new KeyValues("WebResponse");
	UTIL_ProcessElement("MusicData", Response, hObj);
	KeyValuesToFile(Response, "addons/musictest.txt");

	if(!KvJumpToKey(Response, "MusicData") || !KvJumpToKey(Response, "result"))
	{
		delete hObj;
		delete Response;
		return;
	}

	if(KvGetNum(Response, "songCount", 0) < 1)
	{
		delete hObj;
		delete Response;
		return;
	}

	if(!KvJumpToKey(Response, "songs"))
	{
		delete hObj;
		delete Response;
		return;
	}
	
	if(!KvGotoFirstSubKey(Response))
	{
		delete hObj;
		delete Response;
		return;
	}
	
	Handle menu = CreateMenu(MenuHandler_DisplayList);
	SetMenuTitleEx(menu, "[CG] 音乐搜索结果::网易云音乐")
	
	do
	{
		char sid[32], name[32], ar[32], arlist[128], buffer[256], dt[32];
		KvGetString(Response, "name", name, 32);
		KvGetString(Response, "id", sid, 32);
		KvGetString(Response, "dt", dt, 32);
		if(KvJumpToKey(Response, "ar"))
		{
			KvGotoFirstSubKey(Response);
			do
			{
				KvGetString(Response, "name", ar, 32);
				if(arlist[0] != '\0')
					Format(arlist, 128, "%s/%s", arlist, ar);
				else
					Format(arlist, 128, "%s", ar);
			} while (KvGotoNextKey(Response));

			KvGoBack(Response);
			KvGoBack(Response);
		}

		Format(buffer, 256, "%s - %s", name, arlist);
		Format(sid, 32, "%s;%s;", sid, dt);
		AddMenuItemEx(menu, ITEMDRAW_DEFAULT, sid, buffer);
	} while (KvGotoNextKey(Response));
	
	DisplayMenu(menu, client, 0);

	delete hObj;
	delete Response;
}

public int MenuHandler_DisplayList(Handle menu, MenuAction action, int client, int itemNum)
{
	if(action == MenuAction_Select) 
	{
		if(GetGameTime() < g_fNextPlay)
		{
			PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);
			return;
		}

		char info[32], soundname[128];
		GetMenuItem(menu, itemNum, info, 32, _, soundname, 128)
		
		char data[2][32];
		ExplodeString(info, ";", data, 2, 32);
		
		strcopy(g_Sound[szName], 128, soundname);
		strcopy(g_Sound[szLen], 16, data[1]);
		g_Sound[iSongId] = StringToInt(data[0]);
		g_Sound[fLength] = StringToFloat(data[1])*0.001;

		g_fNextPlay = GetGameTime()+g_Sound[fLength];
		
		PrepareSong(GetClientUserId(client), g_Sound[iSongId]);
		
		PrintToChat(client, "%s  \x04服务器正在向CDN节点更新缓存,音乐将在数秒后播放..", PREFIX);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void PrepareSong(int userid, int songid)
{
	char url[256];
	Format(url, 256, "%s%d", CACHED, songid);

#if defined USE_SteamWorks
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	SteamWorks_SetHTTPRequestContextValue(hRequest, userid);
	SteamWorks_SetHTTPCallbacks(hRequest, API_PrepareSong);
	SteamWorks_SendHTTPRequest(hRequest);
#else
	System2_GetPage(API_CachedSong, url, "", "", userid);
#endif
}

#if defined USE_SteamWorks
public int API_PrepareSong(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
	if(bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
		SteamWorks_GetHTTPResponseBodyCallback(hRequest, API_CachedSong, userid);
	else
		LogError("HTTP Response failed: %i", eStatusCode);
	
	CloseHandle(hRequest);
}

public int API_CachedSong(const char[] sData, int userid)
{
	g_fNextPlay = 0.0;

	if(StrEqual(sData, "success!", false) || StrEqual(sData, "file_exists!", false))
		InitPlayer(GetClientOfUserId(userid));
	else
		LogError("Cache song => [%s]", sData);
}
#else
public void API_CachedSong(const char[] output, const int size, CMDReturn status, int userid)
{
	switch(status)
	{
		case CMD_SUCCESS: {if(StrEqual(output, "success!", false) || StrEqual(output, "file_exists!", false)) InitPlayer(GetClientOfUserId(userid)); else LogError("Cache song => [%s]", output);}
		case CMD_ERROR  : {g_fNextPlay = 0.0; LogError("Cache song => [%s]", output);}
	}
}
#endif

void InitPlayer(int client)
{
	if(!IsValidClient(client))
		return;

	if(g_hPlayMenu != INVALID_HANDLE)
		CloseHandle(g_hPlayMenu);

	g_hPlayMenu = CreateMenu(MenuHanlder_Main);
	SetMenuTitle(g_hPlayMenu, "正在播放： %s", g_Sound[szName]);
	AddMenuItem(g_hPlayMenu, "bgmstop", "关闭地图音乐");
	AddMenuItem(g_hPlayMenu, "mainmenu", "打开主菜单");
	AddMenuItem(g_hPlayMenu, "musicvol", "调节音量");
	AddMenuItem(g_hPlayMenu, "musicstop", "关闭点播歌曲");
	SetMenuExitButton(g_hPlayMenu, true);

	for(int i = 1; i <= MaxClients; ++i)
	{
		g_bListen[i] = false;
		g_bPause[i] = false;
		
		if(!IsClientInGame(i))
			continue;

		if(g_bDiable[i])
			continue;

		char murl[192];
		Format(murl, 192, "%s%d&volume=%d", PLAYER, g_Sound[iSongId], g_iVolume[i]);
		DisplayMenu(g_hPlayMenu, i, 15);
		CG_ShowHiddenMotd(i, murl);
		UTIL_StopBGM(i);
	}

	int cost = 200;
	if(FindPluginByFile("zombiereloaded.smx")) cost = 1000;
	Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, "点歌");
	PrintToChat(client, "%s \x01点歌成功!花费\x03%d\x10信用点\x01 余额\x03%i\x10信用点", PREFIX, cost, Store_GetClientCredits(client));
	PrintToChatAll("%s \x04%N\x01点播歌曲[\x0C%s\x01]", PREFIX, client, g_Sound[szName]);
	LogToFileEx(logFile, "\"%L\" 点播了歌曲[%s]", client, g_Sound[szName]);

	CreateTimer(0.1, Timer_GetLyric, g_Sound[iSongId], TIMER_FLAG_NO_MAPCHANGE);

	g_fNextPlay = GetGameTime()+g_Sound[fLength];
}

public Action Timer_GetLyric(Handle timer, int songid)
{
	char url[256];
	Format(url, 256, "%s%d", LYRICS, songid)

#if defined USE_SteamWorks
	Handle hHandle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
	SteamWorks_SetHTTPCallbacks(hHandle, API_GetLyric);
	SteamWorks_SetHTTPRequestContextValue(hHandle, 0);
	SteamWorks_SendHTTPRequest(hHandle);
#else
	System2_DownloadFile(API_GetLyric, url, "addons/sourcemod/data/lyric.txt");
#endif

	ClearArray(array_lyric);
}

#if defined USE_SteamWorks
public int API_GetLyric(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if(bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
	{
		if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, "addons/sourcemod/data/lyric.txt"))
		{
			UTIL_ProcessLyric();
		}
		else 
			LogError("SteamWorks_WriteHTTPResponseBodyToFile failed");
	}

	CloseHandle(hRequest);
}
#else
public void API_GetLyric(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow)
{
	if(finished)
	{
		if(!StrEqual(error, ""))
		{
			LogError("System2 -> API_GetLyric -> Download lyric Error: %s", error);
			return;
		}

		UTIL_ProcessLyric();
	}
}
#endif

void UTIL_ProcessLyric()
{
	Handle hFile;
	if((hFile = OpenFile("addons/sourcemod/data/lyric.txt", "r")) != INVALID_HANDLE)
	{
		UTIL_LyricHud("....等待歌词中....");
		PushArrayString(array_lyric, ">>> Music <<<\n");
		char fileline[128];
		while(ReadFileLine(hFile, fileline, 128))
		{
			if(fileline[0] != '[')
				continue;

			Format(fileline, 128, "%s", fileline[1]);

			int pos;
			while((pos = FindCharInString(fileline, ']')) != -1)
			{
				fileline[pos] = '\\'
				if(fileline[pos+1] == '\0')
					fileline[pos+1] = '\n';
			}
			
			ReplaceString(fileline, 128, "\\", "]");

			char data[2][128], time[2][16];
			if(ExplodeString(fileline, "]", data, 2, 128) != 2)
				continue;

			if(ExplodeString(data[0], ":", time, 2, 16) != 2)
				continue;

			PushArrayCell(array_timer, CreateTimer(StringToFloat(time[0])*60.0+StringToFloat(time[1]), Timer_Lyric, PushArrayString(array_lyric, data[1]), TIMER_FLAG_NO_MAPCHANGE));
		}
		CloseHandle(hFile);
	}
	else LogError("UTIL_ProcessLyric -> OpenFile -> INVALID_HANDLE");

	//DeleteFile("addons/sourcemod/data/lyric.txt");
}

public Action Timer_Lyric(Handle timer, int index)
{
	int idx = FindValueInArray(array_timer, timer);
	if(idx != -1)
		RemoveFromArray(array_timer, idx);

	char lyric[3][128];
	GetArrayString(array_lyric, index-1, lyric[0], 128);
	GetArrayString(array_lyric, index-0, lyric[1], 128);
	if(index+1 < GetArraySize(array_lyric))
	GetArrayString(array_lyric, index+1, lyric[2], 128);
	else strcopy(lyric[2], 128, " >>> End <<< ");

	char buffer[256];
	Format(buffer, 256, "%s%s%s", lyric[0], lyric[1], lyric[2]);
	UTIL_LyricHud(buffer);
}

// Code by ShuFen.jp ** my json is so bad.
void UTIL_ProcessElement(char[] sKey, KeyValues g_hKV, JSONValue hObj)
{
	switch(view_as<JSONType>(json_typeof(hObj)))
	{
		case JSONType_Object:
		{
			// It's another object
			KvJumpToKey(g_hKV, sKey, true);
			IterateJsonObject(view_as<JSONObject>(hObj), g_hKV);
			KvGoBack(g_hKV);
		}
		case JSONType_Array:
		{
			// It's another array
			KvJumpToKey(g_hKV, sKey, true);
			IterateJsonArray(view_as<JSONArray>(hObj), g_hKV);
			KvGoBack(g_hKV);
		}
		case JSONType_String:
		{
			char sString[1024];
			json_string_value(view_as<JSONString>(hObj), sString, sizeof(sString));
			KvSetString(g_hKV, sKey, sString);
		}
		case JSONType_Integer: KvSetNum(g_hKV, sKey, json_integer_value(view_as<JSONInteger>(hObj)));
		case JSONType_Float  : KvSetFloat(g_hKV, sKey, json_real_value(view_as<JSONFloat>(hObj)));
		case JSONType_True   : KvSetNum(g_hKV, sKey, 1);
		case JSONType_False  : KvSetNum(g_hKV, sKey, 0);
		case JSONType_Null   : KvSetString(g_hKV, sKey, "");
	}
}

void IterateJsonArray(JSONArray hArray, KeyValues g_hKV)
{
	for(int iElement = 0; iElement < json_array_size(hArray); iElement++)
	{
		JSONValue hValue = json_array_get(hArray, iElement);
		char sElement[4];
		IntToString(iElement, sElement, 4);
		UTIL_ProcessElement(sElement, g_hKV, hValue);

		CloseHandle(hValue);
	}
}

void IterateJsonObject(JSONObject hObj, KeyValues g_hKV)
{
	JSONObjectIterator hIterator = json_object_iter(hObj);

	while(hIterator != INVALID_HANDLE)
	{
		char sKey[128];
		json_object_iter_key(hIterator, sKey, 128);

		JSONValue hValue = json_object_iter_value(hIterator);

		UTIL_ProcessElement(sKey, g_hKV, hValue);

		CloseHandle(hValue);
		hIterator = json_object_iter_next(hObj, hIterator);
	}
}

void UTIL_LyricHud(const char[] message)
{
	ArrayList array_client = CreateArray();
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client) && !g_bDiable[client] && !g_bPause[client])
		{
			UTIL_StopBGM(client);
			PushArrayCell(array_client, client);
		}

	CG_ShowGameText(message, "30.0", "57 197 187", "-1.0", "0.8", array_client);
	delete array_client;
}

void UTIL_ClearLyric(int client)
{
	ArrayList array_client = CreateArray();
	PushArrayCell(array_client, client);
	CG_ShowGameText(">>> 歌曲已停止播放 <<<", "3.0", "57 197 187", "-1.0", "0.8", array_client);
	delete array_client;
}

void UTIL_StopBGM(int client)
{
	ClientCommand(client, "playgamesound Music.StopAllExceptMusic");
	ClientCommand(client, "playgamesound Music.StopAllMusic");
}