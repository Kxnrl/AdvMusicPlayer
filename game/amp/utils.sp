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
    if(g_bMGLibrary)
        MG_Motd_ShowHiddenMotd(index, url);
    // using corelib
    else if(g_bCoreLib)
        CG_ShowHiddenMotd(index, url);
    // using motdex
    else if(g_bMotdEx)
        MotdEx_ShowHiddenMotd(index, url);
    else
    {
        Handle m_hKv = CreateKeyValues("data");
        KvSetString(m_hKv, "title", "Kyle feat. UMP45");
        KvSetNum(m_hKv, "type", MOTDPANEL_TYPE_URL);
        KvSetString(m_hKv, "msg", url);
        KvSetNum(m_hKv, "cmd", 0);
        ShowVGUIPanel(index, "info", m_hKv, false);
        CloseHandle(m_hKv);
    }

#if defined DEBUG
    UTIL_DebugLog("UTIL_OpenMotd -> %N -> %s", index, url);
#endif
}

void UTIL_RemoveMotd(int index)
{
    if(g_bMGLibrary)
        MG_Motd_RemoveMotd(index);
    // using corelib
    else if(g_bCoreLib)
        CG_RemoveMotd(index);
    // using motdex
    else if(g_bMotdEx)
        MotdEx_RemoveMotd(index);
    else
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
        return;
    }

    // import result to kv tree
    if(!_kv.ImportFromFile(path))
    {
        delete _kv;
        LogError("UTIL_ProcessResult -> Import error!");
        return;
    }

    // can open kv tree
    if(!_kv.GotoFirstSubKey(true))
    {
        delete _kv;
        LogError("UTIL_ProcessResult -> No result!");
        return;
    }

    // create a menu of list
    Handle menu = CreateMenu(MenuHandler_DisplayList);
    int count = 0;
    
#if defined DEBUG
    UTIL_DebugLog("UTIL_ProcessResult -> Start -> %N", client);
#endif

    do
    {
        char key[32], name[64], arlist[128], album[128];

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
                        Format(arlist, 128, "%s/%s", arlist, ar);
                    else
                        FormatEx(arlist, 128, "%s", ar);
                } while (_kv.GotoNextKey(true));
                _kv.GoBack();
            }
            _kv.GoBack();
        }
        else
            strcopy(arlist, 128, "unnamed");

        if(_kv.JumpToKey("al"))
        {
            _kv.GetString("name", album, 128);
            _kv.GoBack();
        }
        else
            strcopy(album, 128, "unknown");

        // add song to menu
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, key, "%T", "search result songs", client, name, arlist, album);
        
#if defined DEBUG
        UTIL_DebugLog("UTIL_ProcessResult -> %d[%s] - %s - %s", _kv.GetNum("id"), name, arlist, album);
#endif
        
        // display 5 items per-page
        if(++count % 5 == 0)
            AddMenuItem(menu, "0", "0", ITEMDRAW_SPACER);
    } while (_kv.GotoNextKey(true));

    // set title
    SetMenuTitle(menu, "%T", "search result title", client, count);
    DisplayMenu(menu, client, 60);

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
    else
        strcopy(album, 128, "unknown");
    
    delete _kv;
}

void UTIL_ProcessLyric(int index)
{
    // if client is not in game
    if(index != 0 && !IsClientInGame(index))
        return;

    // clear lyric array of index
    array_lyric[index].Clear();

    // load data from file
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[index][iSongId]);

    Handle hFile = OpenFile(path, "r");
    if(hFile == null)
    {
        LogError("UTIL_ProcessLyric -> OpenFile -> null -> Load Lyric failed [%d].", g_Sound[index][iSongId]);
        return;
    }

    // pre-line
    Player_LyricHud(index, "5.0", ".....Lyric.....");
    array_lyric[index].PushString(">>> Music <<<\n");

    // processing lyric
    char fileline[128];
    while(ReadFileLine(hFile, fileline, 128))
    {
        if(fileline[0] != '[')
            continue;

        // remove '['
        Format(fileline, 128, "%s", fileline[1]);

        // fix line
        int pos = FindCharInString(fileline, ']');
        if(pos == -1) // wrong line
            continue;

        // it is ending
        if(pos+1 == strlen(fileline))
            StrCat(fileline, 128, "...Music...");

        // get lyric time and lyric string
        char data[2][128], time[2][16];
        if(ExplodeString(fileline, "]", data, 2, 128) != 2)
            continue;

        if(ExplodeString(data[0], ":", time, 2, 16) != 2)
            continue;
        
        // ignore message line
        if(!IsCharNumeric(time[0][0]))
            continue;

        // fix '\n'
        pos = FindCharInString(data[1], '\n');
        if(pos != -1)
            data[1][pos] = '\0';

#if defined DEBUG
        UTIL_DebugLog("UTIL_ProcessLyric -> Index[%d] -> Delay[%.2f] -> Line -> %s", index, StringToFloat(time[0])*60.0+StringToFloat(time[1]), data[1]);
#endif
        array_timer[index].Push(CreateTimer(StringToFloat(time[0])*60.0+StringToFloat(time[1]), Timer_Lyric, array_lyric[index].PushString(data[1]) | (index << 7)));
    }

    if(GetArraySize(array_lyric[index]) > 2)
        Player_LyricHud(index, "300.0", ">>> Music <<<");

    delete hFile;
}

void UTIL_CacheSong(int client, int index)
{
    char url[192];
    FormatEx(url, 192, "%s%d", g_urlCached, g_Sound[index][iSongId]);

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
        Chat(index, "Song is precaching now...", PREFIX);
    else
        ChatAll("Song is precaching now...", PREFIX);

#if defined DEBUG
    UTIL_DebugLog("UTIL_CacheSong -> %N -> %s", index, url);
#endif
}

void UTIL_ShowLyric(int client, const char[] message, const char[] life)
{
    // using corelib
    if(g_bCoreLib)
    {
        CG_ShowGameTextToClient(message, life, "57 197 187", "-1.0", "0.8", client);
        return;
    }

    // we use sync hud
    static Handle hSync;
    if(hSync == INVALID_HANDLE)
        hSync = CreateHudSynchronizer();
    
    // get life from string
    float len = StringToFloat(life);
    
    if(len < 1.0)
    {
        ClearSyncHud(client, hSync);
        return;
    }

    SetHudTextParams(-1.0, 0.8, len, 57, 197, 187, 255, 0, 30.0, 0.0, 0.0);
    ShowSyncHudText(client, hSync, message);
}

void UTIL_CheckDirector()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music");
    if(!DirExists(path))
        CreateDirectory(path, 511);
    else
    {
        // we need clear logs of searching
        Handle hDirectory;
        if((hDirectory = OpenDirectory("addons/sourcemod/data/music")) != INVALID_HANDLE)
        {
            FileType type = FileType_Unknown;
            char filename[128];
            while(ReadDirEntry(hDirectory, filename, 128, type))
            {
                if(type != FileType_File || StrContains(filename, "search_", false) != 0)
                    continue;

                FormatEx(path, 128, "addons/sourcemod/data/music/%s", filename);
                DeleteFile(path);
            }
            CloseHandle(hDirectory);
        }
    }
}

#if defined DEBUG
void UTIL_DebugLog(const char[] log, any ...)
{
    char buffer[512];
    VFormat(buffer, 512, log, 2);
    LogToFileEx("addons/sourcemod/logs/mediasystem.debug.log", buffer);
}
#endif