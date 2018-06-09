/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          player.sp                                      */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
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
    g_Sound[index][iSongId] = 0;
    g_Sound[index][fLength] = 0.0;
    g_Sound[index][szName][0] = '\0';
    g_Sound[index][szSinger][0] = '\0';
    g_Sound[index][szAlbum][0] = '\0';
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

public Action Timer_GetLyric(Handle timer, int index)
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[index][iSongId]);

#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> %N -> checking %s", index, path);
#endif

    // checking lyric cache file.
    if(!FileExists(path))
    {
        char url[256];
        g_cvarLYRICS.GetString(url, 256);
        Format(url, 256, "%s%d", url, g_Sound[index][iSongId]);

#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> Downloading Lyrics -> %N -> %d[%s] -> %s", index, g_Sound[index][iSongId], g_Sound[index][szName], url);
#endif

        if(g_bSystem2)
        {
            System2HTTPRequest hRequest = new System2HTTPRequest(API_GetLyric_System2, url);
            hRequest.SetOutputFile(path);
            hRequest.Any = index;
            hRequest.GET();
            delete hRequest;
        }
        else
        {
            Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
            SteamWorks_SetHTTPCallbacks(hRequest, API_GetLyric_SteamWorks);
            SteamWorks_SetHTTPRequestContextValue(hRequest, index);
            SteamWorks_SendHTTPRequest(hRequest);
            delete hRequest;
        }
    }
    else
    {
#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> Loading Local Lyrics -> %N -> %d[%s] -> %s", index, g_Sound[index][iSongId], g_Sound[index][szName], path);
#endif
        CreateTimer(0.2, UTIL_ProcessLyric, index);
    }

    return Plugin_Stop;
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
    UTIL_DebugLog("Timer_SoundEnd -> %N -> %d[%s]", index, g_Sound[index][iSongId], g_Sound[index][szName]);
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

void Player_ListenMusic(int client, bool cached)
{
    // if enabled cache and not precache
    if(g_cvarECACHE.BoolValue && !cached)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_ListenMusic -> %N -> %d[%s] -> we need precache music", client, g_Sound[client][iSongId], g_Sound[client][szName]);
#endif
        UTIL_CacheSong(client, client);
        return;
    }

    // reset player of index
    Player_Reset(client);

    // get song info
    int iLength;
    UTIL_ProcessSongInfo(client, g_Sound[client][szName], g_Sound[client][szSinger], g_Sound[client][szAlbum], iLength, g_Sound[client][iSongId]);
    g_Sound[client][fLength] = float(iLength);

    // init player
    char murl[192];
    g_cvarPLAYER.GetString(murl, 192);
    Format(murl, 192, "%s%d&volume=%d&cache=%d", murl, g_Sound[client][iSongId], g_iVolume[client], g_cvarECACHE.IntValue);
    UTIL_OpenMotd(client, murl);
    
#if defined DEBUG
    UTIL_DebugLog("Player_ListenMusic -> %N -> [%d]%s -> %.2f", client, g_Sound[client][iSongId], g_Sound[client][szName], g_Sound[client][fLength], murl);
#endif

    // set listen flag
    g_bListen[client] = true;

    // load lyric
    if(g_bLyrics[client])
        CreateTimer(0.1, Timer_GetLyric, client);

    // set song end timer
    g_tTimer[client] = CreateTimer(g_Sound[client][fLength]+0.1, Timer_SoundEnd, client);

    ChatAll("%t", "client current playing", client, g_Sound[client][szName]);

    // re-display menu
    DisplayMainMenu(client);
    
    // handle map music
    if(g_bMapMusic)
    {
        g_bStatus[client] = MapMusic_GetStatus(client);
        MapMusic_SetStatus(client, true);
    }
}

void Player_BroadcastMusic(int client, bool cached)
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
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%d]%s -> Time Out", client, g_Sound[client][iSongId], g_Sound[client][szName]);
#endif
        Chat(client, "%T", "last timeout", client);
        return;
    }

    // if enabled cache and not precache
    if(g_cvarECACHE.BoolValue && !cached)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%d]%s -> we need precache music", client, g_Sound[client][iSongId], g_Sound[client][szName]);
#endif
        UTIL_CacheSong(client, BROADCAST);
        return;
    }

    // get song info
    int iLength;
    UTIL_ProcessSongInfo(client, g_Sound[BROADCAST][szName], g_Sound[BROADCAST][szSinger], g_Sound[BROADCAST][szAlbum], iLength, g_Sound[BROADCAST][iSongId]);

    // if store is available, handle credits
    if(g_bStoreLib)
    {
        int cost = RoundFloat(iLength*g_cvarCREDIT.FloatValue);
        if(Store_GetClientCredits(client) < cost)
        {
            Chat(client, "%T", "no enough money", client, cost);
            return;
        }
        char reason[128];
        FormatEx(reason, 128, "点歌系统点歌[%d.%s]", g_Sound[BROADCAST][iSongId], g_Sound[BROADCAST][szName]);
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, reason);
        Chat(client, "%T", "cost to broadcast", client, cost, g_Sound[BROADCAST][szName]);
    }

    g_Sound[BROADCAST][fLength] = float(iLength);

#if defined DEBUG
    UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%d]%s -> %.2f", client, g_Sound[BROADCAST][iSongId], g_Sound[BROADCAST][szName], g_Sound[BROADCAST][fLength]);
#endif

    ChatAll("%t", "broadcast", client, g_Sound[BROADCAST][szName]);
    LogToFileEx(logFile, "\"%L\" 点播了歌曲[%s - %s]", client, g_Sound[BROADCAST][szName],  g_Sound[BROADCAST][szSinger]);

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
        g_cvarPLAYER.GetString(murl, 192);
        Format(murl, 192, "%s%d&volume=%d&cache=%d", murl, g_Sound[BROADCAST][iSongId], g_iVolume[i], g_cvarECACHE.IntValue);
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
    CreateTimer(0.1, Timer_GetLyric, BROADCAST, TIMER_FLAG_NO_MAPCHANGE);

    // set song end timer
    g_tTimer[BROADCAST] = CreateTimer(g_Sound[BROADCAST][fLength]+0.1, Timer_SoundEnd, BROADCAST);
}