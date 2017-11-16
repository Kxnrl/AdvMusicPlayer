#pragma semicolon 1
#pragma dynamic 4194304

// require extensions
#include <clientprefs>
#include <steamworks>

#pragma newdecls required

// require plugin
#include <motdex>

//definitions
//#define DEBUG

#define PREFIX            "[\x10Music\x01]  "
#define logFile           "addons/sourcemod/logs/advmusicplayer.log"

// global variables
float g_fNextPlay;

bool g_bDiable[MAXPLAYERS+1];
bool g_bBanned[MAXPLAYERS+1];
bool g_bListen[MAXPLAYERS+1];
bool g_bPlayed[MAXPLAYERS+1];
int  g_iVolume[MAXPLAYERS+1];
int  g_iSelect[MAXPLAYERS+1];

enum songinfo
{
    iSongId,
    String:szName[128],
    String:szSinger[64],
    String:szAlbum[64],
    Float:fLength
}

songinfo g_Sound[songinfo];

Handle g_hSyncHUD;
Handle g_cDisable;
Handle g_cVolume;
Handle g_cBanned;

ConVar g_cvarSEARCH;
ConVar g_cvarLYRICS;
ConVar g_cvarPLAYER;

ArrayList array_timer;
ArrayList array_lyric;

public Plugin myinfo = 
{
    name        = "Advance Music Player [SteamWorks]",
    author      = "Kyle",
    description = "Media System",
    version     = "1.0.<commit_count>.<commit_branch> - <commit_date>",
    url         = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
    // register cookies
    g_cDisable = RegClientCookie("media_disable", "", CookieAccess_Private);
    g_cVolume  = RegClientCookie("media_volume",  "", CookieAccess_Private);
    g_cBanned  = RegClientCookie("media_banned",  "", CookieAccess_Private);

    // register commands
    RegConsoleCmd("sm_music",        Command_Music);
    RegConsoleCmd("sm_dj",           Command_Music);
    RegConsoleCmd("sm_stop",         Command_Music);
    RegConsoleCmd("sm_stopmusic",    Command_Music);
    RegConsoleCmd("sm_mapmusic",     Command_Music);

    // register admin commands
    RegAdminCmd("sm_adminmusicstop", Command_AdminStop, ADMFLAG_BAN);
    RegAdminCmd("sm_musicban",       Command_MusicBan,  ADMFLAG_BAN);
    
    // register console variables
    g_cvarSEARCH = CreateConVar("amp_url_search", "https://csgogamers.com/musicserver/api/search.php?s=",   "url for searching music");
    g_cvarLYRICS = CreateConVar("amp_url_lyrics", "https://csgogamers.com/musicserver/api/lyrics.php?id=",  "url for downloading lyric");
    g_cvarPLAYER = CreateConVar("amp_url_player", "https://csgogamers.com/musicserver/api/player.php?id=", "url of motd player");

    // exec configs
    AutoExecConfig(true, "AdvMusicPlayer", "KyleLu");

    // create array list
    array_timer = new ArrayList();
    array_lyric = new ArrayList(ByteCountToCells(128));
    
    // create sync hud
    g_hSyncHUD = CreateHudSynchronizer();
    
    // create data dir
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music");
    if(!DirExists(path))
        CreateDirectory(path, 511);

    // if late load
    for(int client = 1; client <= MaxClients; ++client)
        if(IsValidClient(client))
        {
            OnClientConnected(client);
            if(AreClientCookiesCached(client))
                OnClientCookiesCached(client);
        }

}

public void OnMapEnd()
{
    // reset player
    g_fNextPlay = 0.0;
    g_Sound[iSongId] = 0;
    g_Sound[fLength] = 0.0;
    g_Sound[szName][0] = '\0';
    g_Sound[szSinger][0] = '\0';
    g_Sound[szAlbum][0] = '\0';
    array_timer.Clear();
    array_lyric.Clear();
}

public void OnClientConnected(int client)
{
    // reset client
    g_bPlayed[client] = false;
    g_bDiable[client] = false;
    g_bBanned[client] = false;
    g_bListen[client] = false;
    g_iVolume[client] = 100;
}

public void OnClientCookiesCached(int client)
{
    // load client settings
    char buf[5][4];
    GetClientCookie(client, g_cDisable, buf[0], 4);
    GetClientCookie(client, g_cVolume,  buf[1], 4);
    GetClientCookie(client, g_cBanned,  buf[2], 4);

    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_iVolume[client] = (StringToInt(buf[1]) >= 10) ? StringToInt(buf[1]) : 65;
    g_bBanned[client] = (StringToInt(buf[2]) ==  1);
}

public Action Command_Music(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    // display menu to client
    DisplayMainMenu(client);

    return Plugin_Handled;
}

public Action Command_AdminStop(int client, int args)
{
    // clear all players
    UTIL_ClearMotdAll();

    // notify sound end
    CreateTimer(0.1, Timer_SoundEnd);

    // broadcast
    PrintToChatAll("%s \x02Admin force music stopped!", PREFIX);

    // clear all timers
    while(GetArraySize(array_timer))
    {
        Handle timer = array_timer.Get(0);
        KillTimer(timer);
        array_timer.Erase(0);
    }

    // show hud
    UTIL_LyricHud(">>> Music End <<<", 3.0);
}

public Action Command_MusicBan(int client, int args)
{
    if(args < 1)
        return Plugin_Handled;

    // checkk command arg
    char buffer[16];
    GetCmdArg(1, buffer, 16);
    int target = FindTarget(client, buffer, true);

    if(!IsValidClient(target))
        return Plugin_Handled;

    // ban client
    g_bBanned[target] = !g_bBanned[target];
    SetClientCookie(target, g_cBanned, g_bBanned[target] ? "1" : "0");
    PrintToChatAll("%s \x02%N\x01%s", PREFIX, target, g_bBanned[target] ? "has been \x07banned\x01" : "has been \x04unban");

    return Plugin_Handled;
}

void DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHanlder_Main);
    
    if(g_bPlayed[client])
        SetMenuTitle(menu, "Current playing ▼\nSong: %s\nSinger: %s\nAlbum: %s\n ", g_Sound[szName], g_Sound[szSinger], g_Sound[szAlbum]); 
    else
        SetMenuTitle(menu, "[AMP]  Main menu\n ");

    AddMenuItemEx(menu, g_bPlayed[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "toall",  "broadcast");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "toggle", "Toggle: %s", g_bDiable[client] ? "OFF" : "ON");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "volume", "Volume: %d", g_iVolume[client]);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "stop",   "Stop Music");

    DisplayMenu(menu, client, 30);
}

public int MenuHanlder_Main(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);

        // re-display menu?
        bool reply = true;

        if(strcmp(info, "toall") == 0)
        {
            if(g_bBanned[client])
            {
                PrintToChat(client, "%s  \x10You have been banned", PREFIX);
                return;
            }

            if(GetGameTime() < g_fNextPlay)
            {
                PrintToChat(client, "%s  \x10The last song has not expired, please wait until the end of time", PREFIX);
                return;
            }

            reply = false;
            g_bListen[client] = true;
            PrintToChat(client, "%s  type song( - singer) [Other parameters]", PREFIX);
        }
        else if(strcmp(info, "toggle") == 0)
        {
            g_bDiable[client] = !g_bDiable[client];
            SetClientCookie(client, g_cDisable, g_bDiable[client] ? "1" : "0");
            PrintToChat(client, "%s  \x10Receive Sounnd: %s", PREFIX, g_bDiable[client] ? "\x07OFF" : "\x04ON");
            if(g_bDiable[client] && g_bPlayed[client])
            {
                MotdEx_RemoveMotd(client);
                g_bPlayed[client] = false;
                UTIL_ClearLyric(client);
            }
        }
        else if(strcmp(info, "volume") == 0)
        {
            switch(g_iVolume[client])
            {
                case 100: g_iVolume[client] =  90;
                case  90: g_iVolume[client] =  80;
                case  80: g_iVolume[client] =  70;
                case  70: g_iVolume[client] =  60;
                case  60: g_iVolume[client] =  50;
                case  50: g_iVolume[client] =  40;
                case  40: g_iVolume[client] =  30;
                case  30: g_iVolume[client] =  20;
                case  20: g_iVolume[client] =  10;
                case  10: g_iVolume[client] = 100;
                default : g_iVolume[client] = 100;
            }
            PrintToChat(client, "%s  \x10The volume settings will take effect next time", PREFIX);
        }
        else if(strcmp(info, "stop") == 0)
        {
            UTIL_StopMusic(client);
            PrintToChat(client, "%s  \x04Music stopped!", PREFIX);
        }

        if(reply) DisplayMainMenu(client);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    // if is not within menu
    if(!client || !g_bListen[client])
        return Plugin_Continue;

    g_bListen[client] = false;

    // banned?
    if(g_bBanned[client])
    {
        PrintToChat(client, "%s  \x10You have been banned", PREFIX);
        return Plugin_Stop;
    }

    // playing?
    if(GetGameTime() < g_fNextPlay)
    {
        PrintToChat(client, "%s  \x10The last song has not expired, please wait until the end of time", PREFIX);
        return Plugin_Stop;
    }

    PrintToChat(client, "%s  \x04Searching ...  (Current Engine:  NetesayCloudMusic)", PREFIX);

    char url[256], src[192];
    g_cvarSEARCH.GetString(src, 192);
    FormatEx(url, 256, "%s%s", src, sArgs);
    ReplaceString(url, 256, " ", "+", false);

#if defined DEBUG
    UTIL_DebugLog("OnClientSayCommand -> %N -> %s -> %s", client, sArgs, url);
#endif

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
    SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(client));
    SteamWorks_SetHTTPCallbacks(hRequest, API_SearchMusic);
    SteamWorks_SendHTTPRequest(hRequest);

    return Plugin_Stop;
}

public int API_SearchMusic(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", userid);
        if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
            UTIL_ProcessResult(userid);
        else
            LogError("SteamWorks -> API_SearchMusic -> WriteHTTPResponseBodyToFile failed");
    }
    else
        LogError("SteamWorks -> API_SearchMusic -> HTTP Response failed: %d", eStatusCode);

    CloseHandle(hRequest);
}

void UTIL_ProcessResult(int userid)
{
    int client = GetClientOfUserId(userid);
    
    if(!IsValidClient(client))
        return;

    KeyValues kv = new KeyValues("songs");
    
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", userid);
   
    if(!FileExists(path))
    {
        delete kv;
        LogError("UTIL_ProcessResult -> Download error!");
        return;
    }

    if(!kv.ImportFromFile(path))
    {
        delete kv;
        LogError("UTIL_ProcessResult -> Import error!");
        return;
    }

    if(!kv.GotoFirstSubKey(true))
    {
        delete kv;
        LogError("UTIL_ProcessResult -> No result!");
        return;
    }

    Handle menu = CreateMenu(MenuHandler_DisplayList);
    int count = 0;
    
    do
    {
        char key[32], name[64], arlist[128], album[128];

        kv.GetSectionName(key, 32);
        kv.GetString("name", name, 32);

        if(kv.JumpToKey("ar"))
        {
            if(kv.GotoFirstSubKey(true))
            {
                do
                {
                    char ar[32];
                    kv.GetString("name", ar, 32);
                    if(arlist[0] != '\0')
                        Format(arlist, 128, "%s/%s", arlist, ar);
                    else
                        FormatEx(arlist, 128, "%s", ar);
                } while (kv.GotoNextKey(true));
                kv.GoBack();
            }
            kv.GoBack();
        }
        else
            strcopy(arlist, 128, "unnamed");

        if(kv.JumpToKey("al"))
        {
            kv.GetString("name", album, 128);
            kv.GoBack();
        }
        else
            strcopy(album, 128, "unknown");

        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, key, "%s\nSinger: %s\nAlbum: %s", name, arlist, album);
        count++;
    } while (kv.GotoNextKey(true));

    SetMenuTitle(menu, "[AMP] search result (%d total)\n ", count);
    DisplayMenu(menu, client, 60);

    delete kv;
}

public int MenuHandler_DisplayList(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select) 
    {
        g_iSelect[client] = itemNum;

        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", GetClientUserId(client));
        
        KeyValues kv = new KeyValues("songs");
        kv.ImportFromFile(path);

        char key[32];
        IntToString(itemNum, key, 32);
        kv.JumpToKey(key, true);

        char name[128];
        kv.GetString("name", name, 128);

        int length = kv.GetNum("dt")/1000;

        char arlist[64];
        if(kv.JumpToKey("ar"))
        {
            if(kv.GotoFirstSubKey(true))
            {
                do
                {
                    char ar[32];
                    kv.GetString("name", ar, 32);
                    if(arlist[0] != '\0')
                        Format(arlist, 64, "%s/%s", arlist, ar);
                    else
                        FormatEx(arlist, 64, "%s", ar);
                } while (kv.GotoNextKey(true));
                kv.GoBack();
            }
            kv.GoBack();
        }
        else
            strcopy(arlist, 64, "unnamed");
        
        char album[64];
        if(kv.JumpToKey("al"))
        {
            kv.GetString("name", album, 128);
            kv.GoBack();
        }
        else
            strcopy(album, 128, "unknown");

        DisplayConfirmMenu(client, name, arlist, album, length);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplayConfirmMenu(int client, const char[] name, const char[] arlist, const char[] album, int time)
{
    Handle menu = CreateMenu(MenuHandler_Confirm);
    SetMenuTitle(menu, "Confirm");
    
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "Song: %s", name);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "Singer: %s", arlist);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "Album: %s", album);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "Time: %dm%ds", time/60, time%60);
    
    AddMenuItemEx(menu, ITEMDRAW_SPACER, " ", " ");
    
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "YES");
    
    DisplayMenu(menu, client, 15);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action ==  MenuAction_Select)
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        if(StringToInt(info) == 1)
            UTIL_InitPlayer(client);
    }
}

void UTIL_InitPlayer(int client)
{
    if(GetGameTime() < g_fNextPlay)
    {
        PrintToChat(client, "%s  \x10The last song has not expired, please wait until the end of time", PREFIX);
        return;
    }
    
    if(g_bBanned[client])
    {
        PrintToChat(client, "%s  \x07You have been banned", PREFIX);
        return;
    }

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", GetClientUserId(client));
    
    KeyValues kv = new KeyValues("songs");
    kv.ImportFromFile(path);

    char key[32];
    IntToString(g_iSelect[client], key, 32);
    
    kv.JumpToKey(key, true);

    kv.GetString("name", g_Sound[szName], 128);

    g_Sound[iSongId] = kv.GetNum("id");
    g_Sound[fLength] = kv.GetNum("dt")*0.001;

    if(kv.JumpToKey("ar"))
    {
        if(kv.GotoFirstSubKey(true))
        {
            do
            {
                char ar[32];
                kv.GetString("name", ar, 32);
                if(g_Sound[szSinger][0] != '\0')
                    Format(g_Sound[szSinger], 64, "%s/%s", g_Sound[szSinger], ar);
                else
                    FormatEx(g_Sound[szSinger], 64, "%s", ar);
            } while (kv.GotoNextKey(true));
            kv.GoBack();
        }
        kv.GoBack();
    }
    else
        strcopy(g_Sound[szSinger], 64, "unnamed");
    
    if(kv.JumpToKey("al"))
    {
        kv.GetString("name", g_Sound[szAlbum], 64);
        kv.GoBack();
    }
    else
        strcopy(g_Sound[szAlbum], 64, "unknown");

#if defined DEBUG
    UTIL_DebugLog("UTIL_InitPlayer -> %N -> %s -> %d -> %.2f", client, g_Sound[szName], g_Sound[iSongId], g_Sound[fLength]);
#endif


    PrintToChatAll("%s \x04%N\x01 broadcast [\x0C%s\x01]", PREFIX, client, g_Sound[szName]);
    LogToFileEx(logFile, "\"%L\" broadcast [%s - %s]", client, g_Sound[szName],  g_Sound[szSinger]);

    g_fNextPlay = GetGameTime()+g_Sound[fLength];
    
    char url[192];
    g_cvarPLAYER.GetString(url, 192);

    for(int i = 1; i <= MaxClients; ++i)
    {
        g_bListen[i] = false;

        if(!IsValidClient(i))
            continue;

        if(g_bDiable[i])
            continue;

        g_bPlayed[i] = true;

        char murl[192];
        FormatEx(murl, 192, "%s%d&volume=%d", url, g_Sound[iSongId], g_iVolume[i]);
        DisplayMainMenu(client);
        MotdEx_ShowHiddenMotd(i, murl);

#if defined DEBUG
        UTIL_DebugLog("UTIL_InitPlayer -> %N -> %s", i, murl);
#endif
    }

    CreateTimer(0.1, Timer_GetLyric, g_Sound[iSongId], TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(g_Sound[fLength]+0.1, Timer_SoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SoundEnd(Handle timer)
{
    g_Sound[iSongId] = 0;
    g_Sound[fLength] = 0.0;
    g_Sound[szName][0] = '\0';
    g_Sound[szSinger][0] = '\0';
    g_Sound[szAlbum][0] = '\0';
    
    for(int i = 1; i <= MaxClients; ++i)
        g_bPlayed[i] = false;

    UTIL_LyricHud(">>> End <<<", 3.0);

    return Plugin_Stop;
}

public Action Timer_GetLyric(Handle timer, int songid)
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", songid);
    
    if(!FileExists(path))
    {
        char url[256];
        g_cvarLYRICS.GetString(url, 256);
        Format(url, 256, "%s%d", url, songid);
        
#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> %d -> %s", songid, url);
#endif

        Handle hHandle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPCallbacks(hHandle, API_GetLyric);
        SteamWorks_SetHTTPRequestContextValue(hHandle, 0);
        SteamWorks_SendHTTPRequest(hHandle);
    }
    else
        UTIL_ProcessLyric();
}

public int API_GetLyric(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if(bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[iSongId]);
        if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
            UTIL_ProcessLyric();
        else
            LogError("SteamWorks_WriteHTTPResponseBodyToFile failed");
    }

    CloseHandle(hRequest);
}

void UTIL_ProcessLyric()
{
    array_lyric.Clear();
    
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[iSongId]);

    Handle hFile = OpenFile(path, "r");
    if(hFile == null)
    {
        LogError("UTIL_ProcessLyric -> OpenFile -> null -> Load Lyric failed.");
        return;
    }

    UTIL_LyricHud("....Wating for Lyric....", 5.0);

    array_lyric.PushString(">>> Music <<<\n");

    char fileline[128];
    while(ReadFileLine(hFile, fileline, 128))
    {
        if(fileline[0] != '[')
            continue;

        Format(fileline, 128, "%s", fileline[1]);

        int pos;
        while((pos = FindCharInString(fileline, ']')) != -1)
        {
            fileline[pos] = '\\';
            if(fileline[pos+1] == '\0')
                fileline[pos+1] = '\n';
        }

        ReplaceString(fileline, 128, "\\", "]");

        char data[2][128], time[2][16];
        if(ExplodeString(fileline, "]", data, 2, 128) != 2)
            continue;

        if(ExplodeString(data[0], ":", time, 2, 16) != 2)
            continue;

        array_timer.Push(CreateTimer(StringToFloat(time[0])*60.0+StringToFloat(time[1]), Timer_Lyric, array_lyric.PushString(data[1]), TIMER_FLAG_NO_MAPCHANGE));
    }

    delete hFile;
}

public Action Timer_Lyric(Handle timer, int index)
{
    int idx = array_timer.FindValue(timer);
    if(idx != -1)
        array_timer.Erase(idx);

    char lyric[3][128];
    array_lyric.GetString(index-1, lyric[0], 128);
    array_lyric.GetString(index-0, lyric[1], 128);
    if(index+1 < GetArraySize(array_lyric))
    array_lyric.GetString(index+1, lyric[2], 128);
    else strcopy(lyric[2], 128, " >>> End <<< ");

    char buffer[256];
    FormatEx(buffer, 256, "%s%s%s", lyric[0], lyric[1], lyric[2]);
    UTIL_LyricHud(buffer, 20.0);
}

void UTIL_StopMusic(int client)
{
    MotdEx_RemoveMotd(client);
    g_bPlayed[client] = false;
    UTIL_ClearLyric(client);
}

void UTIL_LyricHud(const char[] message, float life)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsValidClient(client) && !g_bDiable[client] && g_bPlayed[client])
            UTIL_ShowGameText(client, message, life);
}

void UTIL_ClearLyric(int client)
{
    ClearSyncHud(client, g_hSyncHUD);
}

#if defined DEBUG
void UTIL_DebugLog(const char[] log, any ...)
{
    char buffer[512];
    VFormat(buffer, 512, log, 2);
    LogToFileEx("addons/sourcemod/logs/mediasystem.debug.log", buffer);
}
#endif

void UTIL_ClearMotdAll()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i))
            MotdEx_RemoveMotd(i);
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);
	return AddMenuItem(menu, info, m_szBuffer, style);
}

void UTIL_ShowGameText(int client, const char[] message, float life)
{
    SetHudTextParams(-1.0, 0.8, life, 57, 197, 187, 255, 0, 30.0, 0.0, 0.0);
    ShowSyncHudText(client, g_hSyncHUD, message);
}