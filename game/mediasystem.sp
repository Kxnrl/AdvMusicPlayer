//my stock
#include <maoling>

// require extensions
#include <clientprefs>
#include <smjansson>

// cg_core (options)
#include <cg_core>

#if defined _CG_CORE_INCLUDED
    #include <store_cg>
#else
    #include <store>
    #include <weblync> // u can change this if u use webshortcuts (use weblync by default)
#endif

// Use SteamWorks or System2 extension (options) (use system2 by default)
//#define USE_SteamWorks 
//#define DEBUG

#if defined USE_SteamWorks
    #include <SteamWorks> //https://github.com/KyleSanderson/SteamWorks
#else
    #include <system2>  //https://github.com/dordnung/System2
#endif

#pragma dynamic 4194304
#pragma newdecls required

#define PREFIX            "[\x10Music\x01]  "
#define SEARCH            "https://csgogamers.com/musicserver/api/search.php?s="
#define LYRICS            "https://csgogamers.com/musicserver/api/advlyric.php?id="
#define PLAYER            "https://csgogamers.com/musicserver/api/advplayer.php?id="
#define logFile            "addons/sourcemod/logs/musicplayer.log"
#define Default_Cost     200

float g_fNextPlay;

bool g_pStore;
bool g_bDiable[MAXPLAYERS+1];
bool g_bBanned[MAXPLAYERS+1];
bool g_bListen[MAXPLAYERS+1];
bool g_bPlayed[MAXPLAYERS+1];
bool g_bMapBGM[MAXPLAYERS+1];
int g_iVolume[MAXPLAYERS+1];
int g_iBGMVol[MAXPLAYERS+1];

#if !defined _CG_CORE_INCLUDED
int g_iGameTextRef = INVALID_ENT_REFERENCE;
#endif

enum songinfo
{
    iSongId,
    String:szName[128],
    String:szSinger[64],
    Float:fLength
}

songinfo g_Sound[songinfo];

Handle g_cDisable;
Handle g_cVolume;
Handle g_cBanned;
Handle g_cMapBGM;
Handle g_cBGMVol;
Handle g_hMainMenu;
Handle g_hVolMenu;
Handle g_hPlayMenu;
Handle array_timer;
Handle array_lyric;

public Plugin myinfo = 
{
    name        = "Media System",
    author      = "Kyle",
    description = "Media System , Powered by CG Community",
    version     = "1.3",
    url         = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
    g_cDisable =  RegClientCookie("media_disable",    "", CookieAccess_Private);
    g_cVolume  =  RegClientCookie("media_volume",    "", CookieAccess_Private);
    g_cBanned  =  RegClientCookie("media_banned",     "", CookieAccess_Private);
    g_cMapBGM  =  RegClientCookie("media_mapbgm",     "", CookieAccess_Private);
    g_cBGMVol  =  RegClientCookie("media_bgmvol",     "", CookieAccess_Private);

    RegConsoleCmd("sm_music",            Command_Music);
    RegConsoleCmd("sm_dj",                 Command_Music);
    RegConsoleCmd("sm_stop",            Command_MapMusic);
    RegConsoleCmd("sm_stopmusic",        Command_MapMusic);
    RegConsoleCmd("sm_mapmusic",        Command_MapMusic);

    RegAdminCmd("sm_adminmusicstop",    Command_AdminStop, ADMFLAG_BAN);
    RegAdminCmd("sm_musicban",             Command_MusicBan,  ADMFLAG_BAN);

    AddAmbientSoundHook(Hook_AmbientSound);
    
    CreateTimer(10.0, Timer_CheckBGMVolume, _, TIMER_REPEAT);

    PrepareGlobalMenu();

    array_timer = CreateArray();
    array_lyric = CreateArray(ByteCountToCells(128));

    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            OnClientConnected(client);
            if(AreClientCookiesCached(client))
                OnClientCookiesCached(client);
        }
}

public void OnAllPluginsLoaded()
{
    g_pStore = (FindPluginByFile("store.smx") != INVALID_HANDLE);
}

void PrepareGlobalMenu()
{
    //Main Menu
    g_hMainMenu = CreateMenu(MenuHanlder_Main);
    SetMenuTitleEx(g_hMainMenu, "[多媒体点歌系统] 主菜单");
    AddMenuItem(g_hMainMenu, "musictoall",    "点播歌曲给全部人");            // Broadcast music to All
    AddMenuItem(g_hMainMenu, "musicvol",    "调节点歌音量");                // Set volume
    AddMenuItem(g_hMainMenu, "mapbgm",        "地图音乐设置");                // Stop map BGM
    AddMenuItem(g_hMainMenu, "musicstop",    "停止播放音乐");                // Stop play
    AddMenuItem(g_hMainMenu, "musictoggle", "开关接收点歌");                // Block Receive
    SetMenuExitButton(g_hMainMenu, true);

    //VolumeMenu
    g_hVolMenu = CreateMenu(MenuHanlder_SelectVolume);
    SetMenuTitleEx(g_hVolMenu, "[多媒体点歌系统]  音量调整");                // Set Volume
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
    g_bPlayed[client] = false;
    g_bDiable[client] = false;
    g_bBanned[client] = false;
    g_bListen[client] = false;
    g_bMapBGM[client] = true;
    g_iVolume[client] = 65;
    g_iBGMVol[client] = 99;
}

public void OnClientCookiesCached(int client)
{
    char buf[5][4];
    GetClientCookie(client, g_cDisable, buf[0], 4);
    GetClientCookie(client,  g_cVolume, buf[1], 4);
    GetClientCookie(client,  g_cBanned, buf[2], 4);
    GetClientCookie(client,  g_cMapBGM, buf[3], 4);
    GetClientCookie(client,  g_cBGMVol, buf[4], 4);

    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_iVolume[client] = (StringToInt(buf[1]) >= 10) ? StringToInt(buf[1]) : 65;
    g_bBanned[client] = (StringToInt(buf[2]) ==  1);
    g_bMapBGM[client] = (StringToInt(buf[3]) ==  1) ? false : true;
    g_iBGMVol[client] = (strlen(buf[4]) >= 2) ? StringToInt(buf[4]) : 99;
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
        PrintToChat(client, "%s  你的音量已经设置为\x04%s%%", PREFIX, info);    // Set volume to {%d}
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
        if(!strcmp(info, "musictoggle"))
        {
            g_bDiable[client] = !g_bDiable[client];
            SetClientCookie(client, g_cDisable, g_bDiable[client] ? "1" : "0");
            PrintToChat(client, "%s  \x10点歌接收已%s", PREFIX, g_bDiable[client] ? "\x07关闭" : "\x04开启");    // Music Receive is enabled : disabled
            if(g_bDiable[client])
            {
#if defined _CG_CORE_INCLUDED
                CG_RemoveMotd(client);
#else
                WebLync_OpenUrl(client, "about:blank");
#endif
                g_bPlayed[client] = false;
                UTIL_ClearLyric(client);
            }
        }
        else if(!strcmp(info, "musicvol"))
            DisplayMenu(g_hVolMenu, client, 0);
        else if(!strcmp(info, "musicstop"))
            UTIL_StopMusic(client);
        else if(!strcmp(info, "mainmenu"))
            DisplayMenu(g_hMainMenu, client, 0);
        else if(!strcmp(info, "mapbgm"))
            Command_MapMusic(client, 0);
        else if(!strcmp(info, "musictoall"))
        {
            if(g_bBanned[client])
            {
                PrintToChat(client, "%s  \x10你点歌权限被BAN了", PREFIX);    // you have been banned
                return;
            }

            if(GetGameTime() < g_fNextPlay)
            {
                PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);    // music cooldown
                return;
            }

            g_bListen[client] = true;
            PrintToChat(client, "%s  按Y输入 歌名( - 歌手) [小括号内选填]", PREFIX);    // search: songname ( - singer)
        }
    }
}

public int MenuHanlder_PlayPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char info[64];
        GetMenuItem(menu, itemNum, info, 64);
        if(!strcmp(info, "musicstop"))
            UTIL_StopMusic(client);
        else if(!strcmp(info, "mapbgm"))
            Command_MapMusic(client, 0);
    }
}

void UTIL_StopMusic(int client)
{
    #if defined _CG_CORE_INCLUDED
    CG_RemoveMotd(client);
#else
    WebLync_OpenUrl(client, "about:blank");
#endif
    g_bPlayed[client] = false;
    UTIL_ClearLyric(client);
    PrintToChat(client, "%s  \x04音乐已停止播放", PREFIX);        // Music stopped
}

public Action Command_Music(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    DisplayMenu(g_hMainMenu, client, 0);
    
    return Plugin_Handled;
}

public Action Command_MapMusic(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    Handle menu = CreateMenu(MenuHandler_MapBGM);
    SetMenuTitleEx(menu, "[多媒体点歌系统]  地图音乐控制");                                // Map BGM controller
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "status", "状态: %s", g_bMapBGM[client] ? "开" : "关");            // Status on:off
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "volume", "音量: %d", g_iBGMVol[client]);                        // Volume %d
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);

    return Plugin_Handled;
}

public int MenuHandler_MapBGM(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        if(!strcmp(info,"status")) 
        {
            g_bMapBGM[client] = !g_bMapBGM[client];
            SetClientCookie(client, g_cMapBGM, g_bMapBGM[client] ? "0" : "1");
            UTIL_StopBGM(client);
        }
        else if(!strcmp(info,"volume"))
        {
            switch(g_iBGMVol[client])
            {
                case 99: g_iBGMVol[client] = 90;
                case 90: g_iBGMVol[client] = 80;
                case 80: g_iBGMVol[client] = 70;
                case 70: g_iBGMVol[client] = 60;
                case 60: g_iBGMVol[client] = 50;
                case 50: g_iBGMVol[client] = 40;
                case 40: g_iBGMVol[client] = 30;
                case 30: g_iBGMVol[client] = 20;
                case 20: g_iBGMVol[client] = 10;
                case 10: g_iBGMVol[client] = 99;
            }
            UTIL_FadeClientVolume(client, float(g_iBGMVol[client]));
            
            char strVol[4];
            IntToString(g_iBGMVol[client], strVol, 4);
            SetClientCookie(client, g_cBGMVol, strVol);
        }
        Command_MapMusic(client, 0);
    }
    else if(action == MenuAction_Cancel)
    {
        if(itemNum == MenuCancel_ExitBack)
            DisplayMenu(g_hMainMenu, client, 0);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public Action Command_AdminStop(int client, int args)
{
    UTIL_ClearMotdOfAll();

    g_fNextPlay = 0.0;
    PrintToChatAll("%s \x02权限X强行停止了音乐播放!", PREFIX);        // admin force music stopped

    while(GetArraySize(array_timer))
    {
        Handle timer = GetArrayCell(array_timer, 0);
        KillTimer(timer);
        RemoveFromArray(array_timer, 0);
    }

    UTIL_LyricHud(">>> 歌曲已停止播放 <<<");                        // Music stopped
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
    PrintToChatAll("%s \x02%N\x01%s", PREFIX, target, g_bBanned[target] ? "因为乱玩点歌系统,已被\x07封禁\x01点歌权限" : "点歌权限已被\x04解禁");        // {client name} has been banned : unban

    return Plugin_Handled;
}

// Code by Agent Wesker https://forums.alliedmods.net/showthread.php?t=294323
public Action Hook_AmbientSound(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    if(flags != SND_SPAWNING)
        return Plugin_Continue;

    if(!IsValidEntity(entity))
            return Plugin_Continue;

    char classname[32];
    GetEdictClassname(entity, classname, 32);
    if(!StrEqual(classname, "ambient_generic"))
        return Plugin_Continue;

    int len = strlen(sample);
    if(len > 4 && (StrEqual(sample[len-3], "mp3") || StrEqual(sample[len-3], "wav")))
        CreateTimer(0.0, Timer_CheckBGMVolume);

    return Plugin_Changed;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(!client || !g_bListen[client])
        return Plugin_Continue;

    g_bListen[client] = false;

    if(g_bBanned[client])
    {
        PrintToChat(client, "%s  \x07你已被封禁点歌", PREFIX);                        // You have been banned.
        return Plugin_Continue;
    }
    
    if(GetGameTime() < g_fNextPlay)
    {
        PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);        // Music cooldown
        return Plugin_Continue;
    }

    if(g_pStore)
    {
        int cost = Default_Cost;
        if(FindPluginByFile("zombiereloaded.smx")) cost *= 5;
        if(Store_GetClientCredits(client) < cost)
        {
            PrintToChat(client, "%s  \x07你的信用点不足!", PREFIX);                    // you have not enough credits
            return Plugin_Continue;
        }
    }

    PrintToChat(client, "%s  \x04正在搜索音乐(当前选择引擎: 网易云音乐)", PREFIX);    // searching...

    char url[256];
    Format(url, 256, "%s%s", SEARCH, sArgs)
    ReplaceString(url, 256, " ", "+", false);
    
#if defined DEBUG
    UTIL_DebugLog("OnClientSayCommand -> %N -> %s -> %s", client, sArgs, url);
#endif

#if defined USE_SteamWorks
    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
    SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(client));
    SteamWorks_SetHTTPCallbacks(hRequest, API_SearchMusic);
    SteamWorks_SendHTTPRequest(hRequest);
#else
    System2_DownloadFile(API_SearchMusic, url, "addons/sourcemod/data/music_search.json", GetClientUserId(client));
#endif

    return Plugin_Stop;
}

#if defined USE_SteamWorks
public int API_SearchMusic(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, "addons/sourcemod/data/music_search.json"))
            UTIL_ProcessResult(GetClientOfUserId(userid));
        else
            LogError("SteamWorks -> API_SearchMusic -> WriteHTTPResponseBodyToFile failed");
    }
    else
        LogError("SteamWorks -> API_SearchMusic -> HTTP Response failed: %d", eStatusCode);

    CloseHandle(hRequest);
}
#else
public void API_SearchMusic(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int userid)
{
    if(finished)
    {
        if(!StrEqual(error, ""))
        {
            LogError("System2 -> API_SearchMusic -> Download result Error: %s", error);
            return;
        }

        UTIL_ProcessResult(GetClientOfUserId(userid));
    }
}
#endif

void UTIL_ProcessResult(int client)
{
    if(!IsValidClient(client))
        return;

    JSONValue hObj = json_load_file("addons/sourcemod/data/music_search.json");
    KeyValues Response = new KeyValues("WebResponse");
    UTIL_ProcessElement("MusicData", Response, hObj);

    if(!KvJumpToKey(Response, "MusicData") || !KvJumpToKey(Response, "result"))
    {
        delete hObj;
        delete Response;
        return;
    }

    int soundcount = KvGetNum(Response, "songCount", 0);
    if(soundcount < 1)
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
    SetMenuTitleEx(menu, "[CG] 音乐搜索结果 (找到 %d 首单曲)", soundcount);            // Title: search result (%d songs)
    
    do
    {
        char sid[256], name[32], ar[32], arlist[128], buffer[256], dt[32];
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
        Format(sid, 256, "%s;%s", sid, dt);
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, sid, buffer);
    } while (KvGotoNextKey(Response));
    
    DisplayMenu(menu, client, 0);

    delete hObj;
    delete Response;

    DeleteFile("addons/sourcemod/data/music_search.json");
}

public int MenuHandler_DisplayList(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select) 
    {
        if(GetGameTime() < g_fNextPlay)
        {
            PrintToChat(client, "%s  \x10上次点歌未过期,请等待时间结束", PREFIX);        // Music cooldown
            return;
        }

        char info_1[32], info_2[128];
        GetMenuItem(menu, itemNum, info_1, 32, _, info_2, 128)
        
        char data_1[2][32];
        ExplodeString(info_1, ";", data_1, 2, 32);
        
        char data_2[2][64];
        ExplodeString(info_2, " - ", data_2, 2, 64);

        strcopy(g_Sound[szName], 128, data_2[0]);
        strcopy(g_Sound[szSinger], 128, data_2[1]);
        g_Sound[iSongId] = StringToInt(data_1[0]);
        g_Sound[fLength] = StringToFloat(data_1[1])*0.001;

        g_fNextPlay = GetGameTime()+g_Sound[fLength];

        UTIL_InitPlayer(client);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void UTIL_InitPlayer(int client)
{
    if(!IsValidClient(client))
        return;
    
#if defined DEBUG
    UTIL_DebugLog("UTIL_InitPlayer -> %N -> %s -> %d -> %.2f", client, g_Sound[szName], g_Sound[iSongId], g_Sound[fLength]);
#endif
    
    if(g_hPlayMenu != INVALID_HANDLE)
        CloseHandle(g_hPlayMenu);

    g_hPlayMenu = CreateMenu(MenuHanlder_Main);
    SetMenuTitleEx(g_hPlayMenu, "正在播放▼\n歌名: %s\n歌手: %s", g_Sound[szName], g_Sound[szSinger]); // current play: song name ; singer name
    AddMenuItem(g_hPlayMenu, "mainmenu",    "打开主菜单");                // Open main menu
    AddMenuItem(g_hPlayMenu, "mapbgm",        "地图音乐");                // Stop map BGM
    AddMenuItem(g_hPlayMenu, "musicvol",    "调节音量");                // Set volume
    AddMenuItem(g_hPlayMenu, "musicstop",    "关闭点播歌曲");            // Stop music
    SetMenuExitButton(g_hPlayMenu, true);

    for(int i = 1; i <= MaxClients; ++i)
    {
        g_bListen[i] = false;
        
        if(!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if(g_bDiable[i])
            continue;
        
        g_bPlayed[i] = true;

        char murl[192];
        Format(murl, 192, "%s%d&volume=%d", PLAYER, g_Sound[iSongId], g_iVolume[i]);
        DisplayMenu(g_hPlayMenu, i, 15);
#if defined _CG_CORE_INCLUDED
        CG_ShowHiddenMotd(i, murl);
#else
        WebLync_OpenUrl(i, murl);
#endif
        UTIL_StopBGM(i);

#if defined DEBUG
        UTIL_DebugLog("UTIL_InitPlayer -> %N -> %s", i, murl);
#endif
    }

    if(g_pStore)
    {
        int cost = Default_Cost;
#if defined _CG_CORE_INCLUDED
        if(FindPluginByFile("zombiereloaded.smx")) cost *= 5;
        if(FindPluginByFile("jb_stats.smx")) cost *= 2;
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, "点歌");
#else
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost);
#endif
        PrintToChat(client, "%s \x01点歌成功!花费\x03%d\x10信用点\x01 余额\x03%i\x10信用点", PREFIX, cost, Store_GetClientCredits(client));        // Boradcast music successful, cost {%d} credits.
    }

    PrintToChatAll("%s \x04%N\x01点播歌曲[\x0C%s\x01]", PREFIX, client, g_Sound[szName]);    // {client name} broadcase {song name}
    LogToFileEx(logFile, "\"%L\" 点播了歌曲[%s - %s]", client, g_Sound[szName],  g_Sound[szSinger]);

    CreateTimer(0.1, Timer_GetLyric, g_Sound[iSongId], TIMER_FLAG_NO_MAPCHANGE);

    g_fNextPlay = GetGameTime()+g_Sound[fLength];
}

public Action Timer_GetLyric(Handle timer, int songid)
{
    char url[256];
    Format(url, 256, "%s%d", LYRICS, songid)
    
#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> %d -> %s", songid, url);
#endif

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
    else LogError("UTIL_ProcessLyric -> OpenFile -> INVALID_HANDLE -> Load Lyric failed.");

    DeleteFile("addons/sourcemod/data/lyric.txt");
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

public Action Timer_CheckBGMVolume(Handle timer)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(!IsClientInGame(client) || IsFakeClient(client))
            continue;

        if(!g_bMapBGM[client] || g_bPlayed[client])
        {
            UTIL_StopBGM(client);
            continue;
        }

        UTIL_FadeClientVolume(client, float(g_iBGMVol[client]));
    }

    return Plugin_Continue;
}

// Code by Agent Wesker https://forums.alliedmods.net/showthread.php?t=294323
void UTIL_FadeClientVolume(int client, float volume)
{
    float fade;

    if(volume >= 100.0) fade = 0.0;
    else if (volume <= 0.0) fade = 100.0;
    else  fade = (100.0 - volume);

    FadeClientVolume(client, fade, 0.0, 100.0, 0.0);
}

// Code by ShuFen.jp ** my json is so bad. https://github.com/Xectali/POSSESSION_tokyo/tree/master/EarthquakeNotification
void UTIL_ProcessElement(char[] sKey, KeyValues kv, JSONValue hObj)
{
    switch(view_as<JSONType>(json_typeof(hObj)))
    {
        case JSONType_Object:
        {
            // It's another object
            KvJumpToKey(kv, sKey, true);
            IterateJsonObject(view_as<JSONObject>(hObj), kv);
            KvGoBack(kv);
        }
        case JSONType_Array:
        {
            // It's another array
            KvJumpToKey(kv, sKey, true);
            IterateJsonArray(view_as<JSONArray>(hObj), kv);
            KvGoBack(kv);
        }
        case JSONType_String:
        {
            char sString[1024];
            json_string_value(view_as<JSONString>(hObj), sString, sizeof(sString));
            KvSetString(kv, sKey, sString);
        }
        case JSONType_Integer: KvSetNum(kv, sKey, json_integer_value(view_as<JSONInteger>(hObj)));
        case JSONType_Float  : KvSetFloat(kv, sKey, json_real_value(view_as<JSONFloat>(hObj)));
        case JSONType_True   : KvSetNum(kv, sKey, 1);
        case JSONType_False  : KvSetNum(kv, sKey, 0);
        case JSONType_Null   : KvSetString(kv, sKey, "");
    }
}

void IterateJsonArray(JSONArray hArray, KeyValues kv)
{
    for(int iElement = 0; iElement < json_array_size(hArray); iElement++)
    {
        JSONValue hValue = json_array_get(hArray, iElement);
        char sElement[4];
        IntToString(iElement, sElement, 4);
        UTIL_ProcessElement(sElement, kv, hValue);

        CloseHandle(hValue);
    }
}

void IterateJsonObject(JSONObject hObj, KeyValues kv)
{
    JSONObjectIterator hIterator = json_object_iter(hObj);

    while(hIterator != INVALID_HANDLE)
    {
        char sKey[128];
        json_object_iter_key(hIterator, sKey, 128);

        JSONValue hValue = json_object_iter_value(hIterator);

        UTIL_ProcessElement(sKey, kv, hValue);

        CloseHandle(hValue);
        hIterator = json_object_iter_next(hObj, hIterator);
    }
}

void UTIL_LyricHud(const char[] message)
{
#if defined _CG_CORE_INCLUDED
    ArrayList array_client = CreateArray();
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client) && !g_bDiable[client] && g_bPlayed[client])
            PushArrayCell(array_client, client);

    CG_ShowGameText(message, "30.0", "57 197 187", "-1.0", "0.8", array_client);
    delete array_client;
#else
    UTIL_GameText(0, message, "30.0");
#endif
}

void UTIL_ClearLyric(int client)
{
#if defined _CG_CORE_INCLUDED
    ArrayList array_client = CreateArray();
    PushArrayCell(array_client, client);
    CG_ShowGameText(">>> 歌曲已停止播放 <<<", "3.0", "57 197 187", "-1.0", "0.8", array_client);
    delete array_client;
#else
    UTIL_GameText(client, ">>> 歌曲已停止播放 <<<", "3.0");
#endif
}

void UTIL_StopBGM(int client)
{
    ClientCommand(client, "playgamesound Music.StopAllExceptMusic");
    ClientCommand(client, "playgamesound Music.StopAllMusic");
}

#if defined DEBUG
void UTIL_DebugLog(const char[] log, any ...)
{
    char buffer[512];
    VFormat(buffer, 512, log, 2);
    LogToFileEx("addons/sourcemod/logs/mediasystem.debug.log", buffer);
}
#endif

void UTIL_ClearMotdOfAll()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i) && !IsFakeClient(i))
#if defined _CG_CORE_INCLUDED
            CG_RemoveMotd(i);
#else
            WebLync_OpenUrl(i, "about:blank");
#endif
}

#if !defined _CG_CORE_INCLUDED
void UTIL_GameText(int client, const char[] message, const char[] hold)
{
    int entity = -1;
    if(!IsValidEntity(g_iGameTextRef))
    {
        entity = CreateEntityByName("game_text");
        g_iGameTextRef = EntIndexToEntRef(entity);

        char tname[32]
        Format(tname, 32, "game_text_%d", entity);
        DispatchKeyValue(entity,"targetname", tname);
    }
    else entity = EntRefToEntIndex(g_iGameTextRef);
    
    DispatchKeyValue(entity, "message", message);
    DispatchKeyValue(entity, "spawnflags", (client == 0) ? "1" : "0");
    DispatchKeyValue(entity, "channel", "8");
    DispatchKeyValue(entity, "holdtime", hold);
    DispatchKeyValue(entity, "fxtime", "99.9");
    DispatchKeyValue(entity, "fadeout", "0");
    DispatchKeyValue(entity, "fadein", "0");
    DispatchKeyValue(entity, "x", "-1.0");
    DispatchKeyValue(entity, "y", "0.8");
    DispatchKeyValue(entity, "color", "57 197 187");
    DispatchKeyValue(entity, "color2", "57 197 187");
    DispatchKeyValue(entity, "effect", "0");

    DispatchSpawn(entity);

    for(int i = 1; i <= MaxClients; ++i)
        if(IsClientInGame(i) && !IsFakeClient(i) && !g_bDiable[i] && g_bPlayed[i])
        {
            UTIL_StopBGM(i);
            if(client == i) AcceptEntityInput(entity, "Display", i);
        }
}

#endif