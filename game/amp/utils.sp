/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          utils.sp                                       */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void UTIL_OpenMotd(int index, const char[] url)
{
    static KeyValues kv = null;
    if(kv == null)
    {
        kv = new KeyValues("data");
        kv.SetString("title", "Advanced Music Player");
        kv.SetNum("type", MOTDPANEL_TYPE_URL);
        kv.SetNum("cmd", 0);
    }

    kv.SetString("msg", url);
    ShowVGUIPanel(index, "info", kv, false);

#if defined DEBUG
    UTIL_DebugLog("UTIL_OpenMotd -> %N -> %s", index, url);
#endif
}

void UTIL_RemoveMotd(int index)
{
    UTIL_OpenMotd(index, "about:blank");

#if defined DEBUG
    UTIL_DebugLog("UTIL_RemoveMotd -> %N", index);
#endif
}

void UTIL_ProcessResult(int userid)
{
    int client = GetClientOfUserId(userid);

    // ignore not in-game clients
    if(!IsValidClient(client))
        return;

    g_bLocked[client] = false;

    KeyValues _kv = new KeyValues("Song");

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%s_%d.kv", g_EngineName[g_kEngine[client]], userid);

    // check file exists
    if(!FileExists(path))
    {
        delete _kv;
        LogError("UTIL_ProcessResult -> Download error!");
        UTIL_NotifyFailure(client, "failed to process searching results");
        return;
    }

    // import result to kv tree
    if(!_kv.ImportFromFile(path))
    {
        delete _kv;
        LogError("UTIL_ProcessResult -> Import error!");
        UTIL_NotifyFailure(client, "failed to process searching results");
        return;
    }

    // can open kv tree
    if(!_kv.GotoFirstSubKey(true))
    {
        delete _kv;
        LogError("UTIL_ProcessResult -> No result!");
        UTIL_NotifyFailure(client, "failed to process searching results");
        return;
    }

    // create a menu of list
    Menu menu = new Menu(MenuHandler_DisplayList);
    int count = 0;

#if defined DEBUG
    UTIL_DebugLog("UTIL_ProcessResult -> Start -> %N", client);
#endif

    do
    {
        char key[16], title[64], artist[64], album[64];

        _kv.GetSectionName(key, 16);

        _kv.GetString("name",    title, 64, "unnamed");
        _kv.GetString("artist", artist, 64, "V.A.");
        _kv.GetString("album",   album, 64, "unknown");

        // add song to menu
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, key, "%T", "search result songs", client, title, artist, album);

#if defined DEBUG
        UTIL_DebugLog("UTIL_ProcessResult -> %s[%s] - %s - %s", key, title, artist, album);
#endif

        // display 5 items per-page
        if(++count % 5 == 0) menu.AddItem("0", "0", ITEMDRAW_SPACER);

    } while (_kv.GotoNextKey(true));

    // set title
    menu.SetTitle("%T", "search result title", client, count, g_EngineName[g_kEngine[client]], client);
    menu.Display(client, 60);

    delete _kv;
}

void UTIL_ProcessSongInfo(int client, char[] title, char[] artist, char[] album, float &length, char[] sid, kEngine &engine)
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%s_%d.kv", g_EngineName[g_kEngine[client]], GetClientUserId(client));

    KeyValues _kv = new KeyValues("Song");
    _kv.ImportFromFile(path);

    // Go to song
    char key[16];
    IntToString(g_iSelect[client], key, 16);
    _kv.JumpToKey(key, true);

    // Get name
    _kv.GetString("name", title, 64, "unnamed");

    // Get length
    length = _kv.GetFloat("length", 240.0);

    // Get songid
    _kv.GetString("id", sid, 32);

    // Get arlist
    _kv.GetString("artist", artist, 64, "V.A.");

    // Get album
    _kv.GetString("album", album, 64, "unknown");

    
    char source[16];
    _kv.GetString("source", source, 64, "custom");
    if(strcmp(source, "netease") == 0)
        engine = kE_Netease;
    else if(strcmp(source, "tencent") == 0)
        engine = kE_Tencent;
    else if(strcmp(source, "xiami") == 0)
        engine = kE_XiaMi;
    else if(strcmp(source, "kugou") == 0)
        engine = kE_KuGou;
    else if(strcmp(source, "baidu") == 0)
        engine = kE_Baidu;
    else if(strcmp(source, "custom") == 0)
        engine = kE_Custom;

/*
    engine = g_kEngine[client];
*/

    delete _kv;
    
#if defined DEBUG
    UTIL_DebugLog("UTIL_ProcessSongInfo -> index[%N] -> title[%s] -> artist[%s] -> album[%s] -> length[%.1f] -> sid[%s] -> engine[%s]", client, title, artist, album, length, sid, g_EngineName[engine]);
#endif
}

public Action UTIL_ProcessLyric(Handle myself, int index)
{
    // if client is not in game
    if(index != 0 && !IsClientInGame(index))
        return Plugin_Stop;

    // clear lyric array of index
    array_lyric[index].Clear();

    // load data from file
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%s_%s.lrc", g_EngineName[g_Sound[index][eEngine]], g_Sound[index][szSongId]);

    File file = OpenFile(path, "r");
    if(file == null)
    {
        LogError("UTIL_ProcessLyric -> OpenFile -> null -> Load Lyric failed [%s].", path);
        return Plugin_Stop;
    }

    // cleaning...
    for(int i = 0; i < 128; ++i)
        delay_lyric[index][i] = -1.0;

    // pre-line
    Player_LyricHud(index, 15.0, 1.0, ".... Music ....");
    array_lyric[index].PushString(">>> Music <<<\n");

    // processing lyric
    char line[128];
    int array;
    float timer;
    while(file.ReadLine(line, 128))
    {
        if(line[0] != '[')
            continue;

        // remove '['
        Format(line, 128, "%s", line[1]);

        // fix line
        int pos = FindCharInString(line, ']');
        if(pos == -1) // wrong line
            continue;

        // it is ending
        if(pos+1 == strlen(line))
            StrCat(line, 128, "... Music ...");

        // get lyric time and lyric string
        char data[2][128], time[2][16];
        if(ExplodeString(line, "]", data, 2, 128) != 2)
            continue;

        if(ExplodeString(data[0], ":", time, 2, 16) != 2)
            continue;
        
        // ignore message line
        if(!IsCharNumeric(time[0][0]))
            continue;

        TrimString(data[1]);

        if(strlen(data[1]) < 3)
            strcopy(data[1], 128, "... Music ...");

#if defined DEBUG
        UTIL_DebugLog("UTIL_ProcessLyric -> Index[%d] -> Delay[%.2f] -> Line -> %s", index, StringToFloat(time[0])*60.0+StringToFloat(time[1]), data[1]);
#endif
        array = array_lyric[index].PushString(data[1]);
        timer = StringToFloat(time[0])*60.0+StringToFloat(time[1]);
        delay_lyric[index][array] = timer;
        array_timer[index].Push(CreateTimer(timer-0.05, Timer_Clear, index));
        array_timer[index].Push(CreateTimer(timer+0.05, Timer_Lyric, array | (index << 7)));
    }

    if(array_lyric[index].Length > 2)
        Player_LyricHud(index, 15.0, 1.0, ".... Music ....");

    delete file;

    return Plugin_Stop;
}

float UTIL_GetNextLyricTime(int index, int lyric)
{
    if(delay_lyric[index][lyric+1] == -1.0)
        return delay_lyric[index][lyric]+10.0;

    return delay_lyric[index][lyric+1];
}

float UTIL_GetCurtLyricTime(int index, int lyric)
{
    return delay_lyric[index][lyric];
}

void UTIL_CacheSong(int client, int index)
{
    char url[256];
    g_cvarAPIURL.GetString(url, 256);
    Format(url, 256, "%s/?action=cached&engine=%s&song=%s", url, g_EngineName[g_Sound[index][eEngine]], g_Sound[index][szSongId]);

#if defined DEBUG
        UTIL_DebugLog("UTIL_CacheSong -> Index[%d] -> url -> %s", index, url);
#endif

    // 2 vars is one
    int values = GetClientUserId(client) | (index << 7);

    // set timeout to prevent new broadcast request
    g_fNextPlay = GetGameTime()+9999.9;

    if(g_bSystem2)
    {
        System2HTTPRequest hRequest = new System2HTTPRequest(API_PrepareSong_System2, url);
        hRequest.Timeout = 60;
        hRequest.Any = values;
        hRequest.GET();
        delete hRequest;
    }
    else
    {
        Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPRequestContextValue(hRequest, values);
        SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 60);
        SteamWorks_SetHTTPCallbacks(hRequest, API_PrepareSong_SteamWorks);
        SteamWorks_SendHTTPRequest(hRequest);
        delete hRequest;
    }

    g_bLocked[client] = true;

    if(index)
        Chat(index, "%T", "precaching song", client);
    else
    {
        ChatAll("%t", "precaching song");
        g_bCaching = true;
    }
}

void UTIL_ShowLyric(int client, const char[] message, const float hold, const float fx)
{
    // we use sync hud
    static Handle hSync;
    if(hSync == null)
        hSync = CreateHudSynchronizer();

    if(hold < 0.1)
    {
        ClearSyncHud(client, hSync);
        return;
    }

#if defined DEBUG
    UTIL_DebugLog("UTIL_ShowLyric -> %N -> %.2f -> 2%f -> %s", client, hold, fx, message);
#endif

    SetHudTextParamsEx(-1.0, 0.825, hold, {255,20,147,255}, {218,112,214,233}, 2, fx, fx, fx);
    ShowSyncHudText(client, hSync, message);
}

void UTIL_NotifyFailure(int client, const char[] translations)
{
    if(!IsValidClient(client))
        return;

    //"failed to precache song"
    Chat(client, "%T", translations, client);
    DisplayMainMenu(client);
    
    g_bLocked[client] = false;
}

void UTIL_CheckDirector()
{
    BuildPath(Path_SM, logFile, 128, "logs/advmusicplayer.log");

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music");
    if(!DirExists(path))
    {
        CreateDirectory(path, 511);
        return;
    }

        // we need clear logs of searching
    DirectoryListing dir = OpenDirectory(path);
    if(dir == null)
    {
        LogError("UTIL_CheckDirector -> Failed to open dir %s", path);
        return;
    }

    FileType ftype = FileType_Unknown;
    char file[128];
    while(dir.GetNext(file, 128, ftype))
    {
        if(ftype != FileType_File || StrContains(file, "search_", false) != 0)
            continue;

        BuildPath(Path_SM, path, 128, "addons/sourcemod/data/music/%s", file);
        DeleteFile(path);
    }

    delete dir;
}

int UTIL_GetCol(const char[] buffer)
{
    int bytes, buffs;
    int size = strlen(buffer)+1;

    for(int x = 0; x < size; ++x)
    {
        if(buffer[x] == '\0')
            break;

        if(buffs == 2)
        {
            bytes++;
            buffs=0;
            continue;
        }

        if(!IsChar(buffer[x]))
        {
            buffs++;
            continue;
        }

        bytes++;
    }
    
    return bytes;
}

bool IsChar(char c)
{
    if(0 <= c <= 126)
        return true;

    return false;
}

#if defined DEBUG
void UTIL_DebugLog(const char[] log, any ...)
{
    static char debugLog[128];
    if(debugLog[0] == '\0')
        BuildPath(Path_SM, debugLog, 128, "logs/advmusicplayer.debug.log");
    
    char buffer[512];
    VFormat(buffer, 512, log, 2);
    LogToFileEx(debugLog, buffer);
}
#endif