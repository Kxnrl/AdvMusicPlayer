/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          utils.sp                                       */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
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

    KeyValues _kv = new KeyValues("songs");

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", userid);

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
        char key[32], name[32], arlist[64], album[64];

        _kv.GetSectionName(key, 32);
        _kv.GetString("name", name, 32);

        if(_kv.JumpToKey("ar"))
        {
            if(_kv.GotoFirstSubKey(true))
            {
                do
                {
                    char ar[32];
                    _kv.GetString("name", ar, 32);
                    if(arlist[0] != '\0')
                        Format(arlist, 64, "%s/%s", arlist, ar);
                    else
                        FormatEx(arlist, 64, "%s", ar);
                } while (_kv.GotoNextKey(true));
                _kv.GoBack();
            }
            _kv.GoBack();
        }
        else strcopy(arlist, 64, "unnamed");

        if(_kv.JumpToKey("al"))
        {
            _kv.GetString("name", album, 64);
            _kv.GoBack();
        }
        else strcopy(album, 64, "unknown");

        // add song to menu
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, key, "%T", "search result songs", client, name, arlist, album);
        
#if defined DEBUG
        UTIL_DebugLog("UTIL_ProcessResult -> %d[%s] - %s - %s", _kv.GetNum("id"), name, arlist, album);
#endif
        
        // display 5 items per-page
        if(++count % 5 == 0)
            menu.AddItem("0", "0", ITEMDRAW_SPACER);
    } while (_kv.GotoNextKey(true));

    // set title
    menu.SetTitle("%T", "search result title", client, count);
    menu.Display(client, 60);

    delete _kv;
}

void UTIL_ProcessSongInfo(int index, char[] name, char[] arlist, char[] album, int &length, int &sid)
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", GetClientUserId(index));

    KeyValues _kv = new KeyValues("songs");
    _kv.ImportFromFile(path);

    // Go to song
    char key[32];
    IntToString(g_iSelect[index], key, 32);
    _kv.JumpToKey(key, true);

    // Get name
    _kv.GetString("name", name, 128);

    // Get length
    length = _kv.GetNum("dt")/1000;
    
    // Get songid
    sid = _kv.GetNum("id");

    // Get arlist
    if(_kv.JumpToKey("ar"))
    {
        if(_kv.GotoFirstSubKey(true))
        {
            do
            {
                char ar[32];
                _kv.GetString("name", ar, 32);
                if(arlist[0] != '\0')
                    Format(arlist, 64, "%s/%s", arlist, ar);
                else
                    FormatEx(arlist, 64, "%s", ar);
            } while (_kv.GotoNextKey(true));
            _kv.GoBack();
        }
        _kv.GoBack();
    }
    else
        strcopy(arlist, 64, "unnamed");
    
    // Get album
    if(_kv.JumpToKey("al"))
    {
        _kv.GetString("name", album, 128);
        _kv.GoBack();
    }
    else strcopy(album, 128, "unknown");

    delete _kv;
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
    BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[index][iSongId]);

    File file = OpenFile(path, "r");
    if(file == null)
    {
        LogError("UTIL_ProcessLyric -> OpenFile -> null -> Load Lyric failed [%d].", g_Sound[index][iSongId]);
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

        // fix '\n'
        //pos = FindCharInString(data[1], '\n');
        //if(pos != -1)
        //    data[1][pos] = '\0';
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
    char url[192];
    g_cvarCACHED.GetString(url, 192);
    Format(url, 192, "%s%d", url, g_Sound[index][iSongId]);

    // 2 vars is one
    int values = client | (index << 7);

    // set timeout to prevent new broadcast request
    g_fNextPlay = GetGameTime()+9999.9;

    if(g_bSystem2)
    {
        System2HTTPRequest hRequest = new System2HTTPRequest(API_PrepareSong_System2, url);
        hRequest.Any = values;
        hRequest.GET();
        delete hRequest;
    }
    else
    {
        Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPRequestContextValue(hRequest, values);
        SteamWorks_SetHTTPCallbacks(hRequest, API_PrepareSong_SteamWorks);
        SteamWorks_SendHTTPRequest(hRequest);
        delete hRequest;
    }

    if(index)
        Chat(index, "%T", "precaching song");
    else
        ChatAll("%t", "precaching song");
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
}

void UTIL_CheckDirector()
{
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
    char buffer[512];
    VFormat(buffer, 512, log, 2);
    LogToFileEx("addons/sourcemod/logs/advmusicplayer.debug.log", buffer);
}
#endif