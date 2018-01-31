/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          player.sp                                      */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle   https://ump45.moe                  */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



void Player_InitPlayer()
{
    // create array for each client
    for(int index = 0; index <= MaxClients; ++index)
    {
        array_timer[index] = new ArrayList();
        array_lyric[index] = new ArrayList(ByteCountToCells(128));
    }
}

void Player_Reset(int index, bool removeMotd = false)
{
    // we need reset nextplay time
    if(index == BROADCAST)
        g_fNextPlay = 0.0;

    // clear song end timer
    if(g_tTimer[index] != INVALID_HANDLE)
        KillTimer(g_tTimer[index]);
    g_tTimer[index] = INVALID_HANDLE;

    // clear lyric timer
    while(GetArraySize(array_timer[index]))
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
            MapMusic_SetStatus(index, false);
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
        FormatEx(url, 256, "%s%d", g_urlLyrics, g_Sound[index][iSongId]);
        
#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> %N -> %d[%s] -> %s", index, g_Sound[index][iSongId], g_Sound[index][szName], url);
#endif

        if(g_bSystem2)
            System2_DownloadFile(API_GetLyric_System2, url, path, index);
        else
        {
            Handle hHandle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
            SteamWorks_SetHTTPCallbacks(hHandle, API_GetLyric_SteamWorks);
            SteamWorks_SetHTTPRequestContextValue(hHandle, index);
            SteamWorks_SendHTTPRequest(hHandle);
        }
    }
    else
        UTIL_ProcessLyric(index);
}

public Action Timer_Lyric(Handle timer, int values)
{
    // check index
    int lyrics_index = values & 0x7f;
    int player_index = values >> 7;

    // find and erase index of timer in timer array
    int idx = array_timer[player_index].FindValue(timer);
    if(idx != -1)
        array_timer[player_index].Erase(idx);

    // get lyric in array
    char lyric[3][128];
    array_lyric[player_index].GetString(lyrics_index-1, lyric[0], 128);
    array_lyric[player_index].GetString(lyrics_index-0, lyric[1], 128);
    if(lyrics_index+1 < GetArraySize(array_lyric[player_index]))
    array_lyric[player_index].GetString(lyrics_index+1, lyric[2], 128);
    else strcopy(lyric[2], 128, " >>> End <<< ");

    // display lyric
    char buffer[384];
    FormatEx(buffer, 384, "  %s\n→  %s\n  %s", lyric[0], lyric[1], lyric[2]);
    Player_LyricHud(player_index, "30.0", buffer);
    
#if defined DEBUG
    UTIL_DebugLog("Timer_Lyric -> lyrics_index[%d] -> player_index[%d]", lyrics_index, player_index);
    UTIL_DebugLog("Timer_Lyric -> %s", lyric[0]);
    UTIL_DebugLog("Timer_Lyric -> %s", lyric[1]);
    UTIL_DebugLog("Timer_Lyric -> %s", lyric[2]);
#endif
}

void Player_LyricHud(int index, const char[] life, const char[] message)
{
    // if broadcast
    if(index == BROADCAST)
    {
        // loop all client who is playing
        for(int client = 1; client <= MaxClients; ++client)
            if(IsValidClient(client) && g_bPlayed[client] && g_bLyrics[client])
                UTIL_ShowLyric(client, message, life);
    }
    else
        UTIL_ShowLyric(index, message, life);
    
#if defined DEBUG
    UTIL_DebugLog("Player_LyricHud -> %N -> %s -> %s", index, life, message);
#endif
}

public Action Timer_SoundEnd(Handle timer, int index)
{
#if defined DEBUG
    UTIL_DebugLog("Timer_SoundEnd -> %N -> %d[%s]", index, g_Sound[index][iSongId], g_Sound[index][szName]);
#endif

    // reset timer
    g_tTimer[index] = INVALID_HANDLE;

    // reset player of index
    Player_Reset(index);

    // if broadcast
    if(index == 0)
        for(int i = 1; i <= MaxClients; ++i)
            if(IsValidClient(i) && g_bPlayed[i] && !g_bListen[i])
            {
                Player_Reset(i, true);
                if(g_bLyrics[i])
                    Player_LyricHud(i, "2.0", ">>> Music End <<<");
            }

    return Plugin_Stop;
}

void Player_ListenMusic(int client, bool cached)
{
    // if enabled cache and not precache
    if(g_iEnableCache && !cached)
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
    FormatEx(murl, 192, "%s%d&volume=%d&cache=%d&proxy=%d", g_urlPlayer, g_Sound[client][iSongId], g_iVolume[client], g_iEnableCache, g_iEnableProxy);
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
        MapMusic_SetStatus(client, true);
}

void Player_BroadcastMusic(int client, bool cached)
{
    // ban?
    if(g_bBanned[client])
    {
        Chat(client, "%t", "banned notice");
        return;
    }

    // if timeout 
    if(GetGameTime() < g_fNextPlay)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%d]%s -> Time Out", client, g_Sound[client][iSongId], g_Sound[client][szName]);
#endif
        Chat(client, "%t", "last timeout");
        return;
    }

    // if enabled cache and not precache
    if(g_iEnableCache && !cached)
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
    g_Sound[BROADCAST][fLength] = float(iLength);

#if defined DEBUG
    UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%d]%s -> %.2f", client, g_Sound[BROADCAST][iSongId], g_Sound[BROADCAST][szName], g_Sound[BROADCAST][fLength]);
#endif

    // if store is available, handle credits
    if(g_bStoreLib)
    {
        int cost = RoundFloat(g_Sound[BROADCAST][fLength]*g_fFactorCredits);
        char reason[128];
        FormatEx(reason, 128, "点歌系统点歌[%d.%s]", g_Sound[BROADCAST][iSongId], g_Sound[BROADCAST][szName]);
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, reason);
        Chat(client, "%t", "cost to broadcast", cost, g_Sound[BROADCAST][szName]);
    }

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
        FormatEx(murl, 192, "%s%d&volume=%d&cache=%d&proxy=%d", g_urlPlayer, g_Sound[BROADCAST][iSongId], g_iVolume[i], g_iEnableCache, g_iEnableProxy);
        DisplayMainMenu(i);
        UTIL_OpenMotd(i, murl);
        
        // handle map music
        if(g_bMapMusic)
            MapMusic_SetStatus(i, true);

#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> Handle clients -> %N -> %s", i, murl);
#endif
    }

    // load lyric
    CreateTimer(0.1, Timer_GetLyric, BROADCAST, TIMER_FLAG_NO_MAPCHANGE);
    
    // set song end timer
    g_tTimer[BROADCAST] = CreateTimer(g_Sound[BROADCAST][fLength]+0.1, Timer_SoundEnd, BROADCAST);
}