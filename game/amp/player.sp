/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          player.sp                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Player_InitPlayer()
{
    // create array for each client
    int size = ByteCountToCells(128);
    for(int index = 0; index <= MaxClients; ++index)
    {
        array_timer[index] = new ArrayList();
        array_lyric[index] = new ArrayList(size);

        for(int lyric = 0; lyric < 128; ++lyric)
            delay_lyric[index][lyric] = -1.0;
    } 
}

void Player_Reset(int index, bool removeMotd = false)
{
    // we need reset nextplay time
    if(index == BROADCAST)
        g_fNextPlay = 0.0;

    // clear song end timer
    if(g_tTimer[index] != null)
        KillTimer(g_tTimer[index]);
    g_tTimer[index] = null;

    // clear lyric timer
    while(array_timer[index].Length > 0)
    {
        Handle timer = array_timer[index].Get(0);
        KillTimer(timer);
        array_timer[index].Erase(0);
    }

    // player status
    g_bPlayed[index] = false;
    g_bListen[index] = false;

    // song info
    g_Sound[index][fLength] = 0.0;
    g_Sound[index][szSongId][0] = '\0';
    g_Sound[index][szTitle] [0] = '\0';
    g_Sound[index][szArtist][0] = '\0';
    g_Sound[index][szAlbum] [0] = '\0';
    g_Sound[index][eEngine] = kE_Netease;
    array_timer[index].Clear();
    array_lyric[index].Clear();

    if(IsValidClient(index))
    {
        // need remove motd?
        if(removeMotd)
            UTIL_RemoveMotd(index);
    
        // handle map music
        if(g_bMapMusic)
            MapMusic_SetStatus(index, g_bStatus[index]);
    }
    
#if defined DEBUG
    UTIL_DebugLog("Player_Reset -> %N -> %b", index, removeMotd);
#endif
}

static void Player_LoadLyric(int index)
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%s_%s.lrc", g_EngineName[g_Sound[index][eEngine]], g_Sound[index][szSongId]);

#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> %N -> checking %s", index, path);
#endif

    // checking lyric cache file.
    if(FileExists(path))
    {
#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> Loading Local Lyrics -> %N -> %s[%s] -> %s", index, g_Sound[index][szSongId], g_Sound[index][szTitle], path);
#endif
        CreateTimer(g_cvarLRCDLY.FloatValue, UTIL_ProcessLyric, index);
        return;
    }

    char url[256];
    g_cvarAPIURL.GetString(url, 256);
    Format(url, 256, "%s/?action=lyrics&engine=%s&song=%s", url, g_EngineName[g_Sound[index][eEngine]], g_Sound[index][szSongId]);

#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> Downloading Lyrics -> %N -> %s[%s] -> %s", index, g_Sound[index][szSongId], g_Sound[index][szTitle], url);
#endif

    DataPack pack = new DataPack();
    pack.WriteCell(index);
    pack.WriteFloat(GetGameTime());
    pack.Reset();

    if(g_bSystem2)
    {
        System2HTTPRequest hRequest = new System2HTTPRequest(API_GetLyric_System2, url);
        hRequest.Timeout = 30;
        hRequest.SetOutputFile(path);
        hRequest.Any = pack;
        hRequest.GET();
        delete hRequest;
    }
    else
    {
        Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPCallbacks(hRequest, API_GetLyric_SteamWorks);
        SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 30);
        SteamWorks_SetHTTPRequestContextValue(hRequest, pack);
        SteamWorks_SendHTTPRequest(hRequest);
        delete hRequest;
    }
}

public Action Timer_Clear(Handle timer, int player_index)
{
    // find and erase index of timer in timer array
    int idx = array_timer[player_index].FindValue(timer);
    if(idx == -1)
    {
        LogError("Timer_Clear -> Exception -> player_index[%d]", player_index);
        return Plugin_Stop;
    }

    array_timer[player_index].Erase(idx);

    Player_LyricHud(player_index, 0.0, 0.0, "");

#if defined DEBUG
    UTIL_DebugLog("Timer_Clear -> player_index[%d]", player_index);
#endif

    return Plugin_Stop;
}

public Action Timer_Lyric(Handle timer, int values)
{
    // check index
    int lyrics_index = values & 0x7f;
    int player_index = values >> 7;

    // find and erase index of timer in timer array
    int idx = array_timer[player_index].FindValue(timer);
    if(idx == -1)
    {
        LogError("Timer_Lyric -> Exception -> lyrics_index[%d] -> player_index[%d]", lyrics_index, player_index);
        return Plugin_Stop;
    }

    array_timer[player_index].Erase(idx);

    // get lyric in array
    char lyric[128];
    array_lyric[player_index].GetString(lyrics_index, lyric, 128);
    
    // lyric timer
    float time = UTIL_GetCurtLyricTime(player_index, lyrics_index);
    float next = UTIL_GetNextLyricTime(player_index, lyrics_index);

    // display lyric
    int bytes = UTIL_GetCol(lyric);
    float kp = next-time;
    float fx = (kp-1.0)/float(bytes);

    Player_LyricHud(player_index, kp, fx, lyric);

#if defined DEBUG
    UTIL_DebugLog("Timer_Lyric -> lyrics_index[%d] -> player_index[%d]", lyrics_index, player_index);
    UTIL_DebugLog("Timer_Lyric -> %.2f:%.2f -> %.2f:%.2f ->%s", time, next, fx, kp, lyric);
#endif

    return Plugin_Stop;
}

void Player_LyricHud(int index, float hold, float fx, const char[] message)
{
    // if broadcast
    if(index == BROADCAST)
    {
        // loop all client who is playing
        for(int client = 1; client <= MaxClients; ++client)
            if(IsValidClient(client) && g_bPlayed[client] && g_bLyrics[client])
                UTIL_ShowLyric(client, message, hold, fx);
    }
    else UTIL_ShowLyric(index, message, hold, fx);

#if defined DEBUG
    UTIL_DebugLog("Player_LyricHud -> %N -> %.1f -> %.1f -> %s", index, hold, fx, message);
#endif
}

public Action Timer_SoundEnd(Handle timer, int index)
{
#if defined DEBUG
    UTIL_DebugLog("Timer_SoundEnd -> %N -> %s[%s]", index, g_Sound[index][szSongId], g_Sound[index][szTitle]);
#endif

    // reset timer
    g_tTimer[index] = null;

    // reset player of index
    Player_Reset(index);

    // if broadcast
    if(index == 0)
        for(int i = 1; i <= MaxClients; ++i)
            if(IsValidClient(i) && g_bPlayed[i] && !g_bListen[i])
            {
                Player_Reset(i, true);
                if(g_bLyrics[i])
                    Player_LyricHud(i, 2.0, 0.3, "......");
            }

    return Plugin_Stop;
}

void Player_ListenMusic(int client, bool cached = false)
{
    // reset player of index
    Player_Reset(client, false);

    // load song info
    UTIL_ProcessSongInfo(client, g_Sound[client][szTitle], g_Sound[client][szArtist], g_Sound[client][szAlbum], g_Sound[client][fLength], g_Sound[client][szSongId], g_Sound[client][eEngine]);

    // if enabled cache and not precache
    if(!cached)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_ListenMusic -> %N -> %s[%s] -> we need precache music", client, g_Sound[client][szSongId], g_Sound[client][szTitle]);
#endif
        UTIL_CacheSong(client, client);
        return;
    }

    // init player
    char murl[192];
    g_cvarAPIURL.GetString(murl, 192);
    Format(murl, 192, "%s/?action=player&volume=%d&engine=%s&song=%s", murl, g_iVolume[client], g_EngineName[g_Sound[client][eEngine]], g_Sound[client][szSongId]);
    UTIL_OpenMotd(client, murl);

#if defined DEBUG
    UTIL_DebugLog("Player_ListenMusic -> %N -> [%s]%s -> %.2f", client, g_Sound[client][szSongId], g_Sound[client][szTitle], g_Sound[client][fLength], murl);
#endif

    // set listen flag
    g_bListen[client] = true;

    // set lock flag
    g_bLocked[client] = false;

    // load lyric
    if(g_bLyrics[client])
        Player_LoadLyric(client);

    // set song end timer
    g_tTimer[client] = CreateTimer(g_Sound[client][fLength]+0.1, Timer_SoundEnd, client);

    ChatAll("%t", "client current playing", client, g_Sound[client][szTitle], g_EngineName[g_Sound[client][eEngine]], client);

    // re-display menu
    DisplayMainMenu(client);

    // handle map music
    if(g_bMapMusic)
    {
        g_bStatus[client] = MapMusic_GetStatus(client);
        MapMusic_SetStatus(client, true);
    }
}

void Player_BroadcastMusic(int client, bool cached = false)
{
    // ban?
    if(g_bBanned[client])
    {
        Chat(client, "%T", "banned notice", client);
        return;
    }

    // if timeout 
    if(GetGameTime() < g_fNextPlay)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> Time Out", client, g_Sound[client][szSongId], g_Sound[client][szTitle]);
#endif
        Chat(client, "%T", "last timeout", client);
        return;
    }
    
    // get song info
    UTIL_ProcessSongInfo(client, g_Sound[BROADCAST][szTitle], g_Sound[BROADCAST][szArtist], g_Sound[BROADCAST][szAlbum], g_Sound[BROADCAST][fLength], g_Sound[BROADCAST][szSongId], g_Sound[BROADCAST][eEngine]);

    // if store is available, handle credits
    if(g_bStoreLib)
    {
        int cost = RoundFloat(g_Sound[BROADCAST][fLength]*g_cvarCREDIT.FloatValue);
        if(Store_GetClientCredits(client) < cost)
        {
            Chat(client, "%T", "no enough money", client, cost);
            return;
        }
        char reason[128];
        FormatEx(reason, 128, "点歌系统点歌[%s.%s]", g_Sound[BROADCAST][szSongId], g_Sound[BROADCAST][szTitle]);
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, reason);
        Chat(client, "%T", "cost to broadcast", client, cost, g_Sound[BROADCAST][szTitle]);
    }

    // if enabled cache and not precache
    if(!cached)
    {
        if(g_bCaching)
        {
            Chat(client, "Global caching");
            return;
        }

#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> we need precache music", client, g_Sound[client][szSongId], g_Sound[client][szTitle]);
#endif
        UTIL_CacheSong(client, BROADCAST);
        return;
    }

    // set lock flag
    g_bLocked[client] = false;

#if defined DEBUG
    UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> %.2f", client, g_Sound[BROADCAST][szSongId], g_Sound[BROADCAST][szTitle], g_Sound[BROADCAST][fLength]);
#endif

    ChatAll("%t", "broadcast", client, g_Sound[BROADCAST][szTitle], g_EngineName[g_Sound[BROADCAST][eEngine]]);
    LogToFileEx(logFile, "\"%L\" 点播了歌曲[%s - %s]", client, g_Sound[BROADCAST][szTitle],  g_Sound[BROADCAST][szArtist]);

    // set timeout
    g_fNextPlay = GetGameTime()+g_Sound[BROADCAST][fLength];

    for(int i = 1; i <= MaxClients; ++i)
    {
        g_bHandle[i] = false;

        // ignore fakeclient and not in-game client
        if(!IsValidClient(i))
            continue;

        // ignore client who sets disabled
        if(g_bDiable[i])
            continue;

        // reset player
        Player_Reset(i, false);

        // set playing flag
        g_bPlayed[i] = true;

        // set song info
        g_Sound[i] = g_Sound[BROADCAST];

        // init player
        char murl[192];
        g_cvarAPIURL.GetString(murl, 192);
        Format(murl, 192, "%s/?action=player&volume=%d&engine=%s&song=%s", murl, g_iVolume[i], g_EngineName[g_Sound[BROADCAST][eEngine]], g_Sound[BROADCAST][szSongId]);
        DisplayMainMenu(i);
        UTIL_OpenMotd(i, murl);

        // handle map music
        if(g_bMapMusic)
        {
            g_bStatus[i] = MapMusic_GetStatus(i);
            MapMusic_SetStatus(i, true);
        }

#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> Handle clients -> %N -> %s", i, murl);
#endif
    }

    // load lyric
    Player_LoadLyric(BROADCAST);

    // set song end timer
    g_tTimer[BROADCAST] = CreateTimer(g_Sound[BROADCAST][fLength]+1.0, Timer_SoundEnd, BROADCAST);
}