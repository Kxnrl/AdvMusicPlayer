/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          player.sp                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/27 04:52:19                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Player_InitPlayer()
{
    // INIT 
    g_Player.m_Request = new ArrayList();

    // GLOBAL RESET
    g_Player.Reset();

    CreateTimer(0.02, Timer_Interval, _, TIMER_REPEAT);

    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
}

public Action Timer_Interval(Handle timer)
{
    if (g_Player.m_Player == null)
        return Plugin_Continue;

    if (!g_Player.m_Player.IsFinished)
    {
        Player_DisplayLyric();
        return Plugin_Continue;
    }

#if defined DEBUG
    UTIL_DebugLog("Player Finished -> %s[%s]", g_Player.m_Song, g_Player.m_Title);
#endif

    // reset player of index
    Player_Reset();

    // clear all
    Player_LyricHud(2.0, 0.3, "......");
    for(int i = 1; i <= MaxClients; ++i)
    {
        if (IsValidClient(i))
        {
            // mapmusic
            MapMusic_SetStatus(i, g_bStatus[i]);
        }
    }

    return Plugin_Continue;
}

void Player_Reset()
{
    // we need reset nextplay time
    g_fNextPlay = 0.0;

    // song info
    g_Player.Reset();

#if defined DEBUG
    UTIL_DebugLog("Player_Reset");
#endif
}

static void Player_LoadLyric()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/lyric_%s_%s.lrc", g_EngineName[g_Player.m_Engine], g_Player.m_Song);

#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> checking %s", path);
#endif

    // checking lyric cache file.
    if (FileExists(path))
    {
#if defined DEBUG
        UTIL_DebugLog("Timer_GetLyric -> Loading Local Lyrics -> %s[%s] -> %s", g_Player.m_Song, g_Player.m_Title, path);
#endif
        CreateTimer(g_Cvars.lyrics.FloatValue, UTIL_ProcessLyric);
        return;
    }

    char url[256];
    g_Cvars.apiurl.GetString(url, 256);
    Format(url, 256, "%s/?action=lyrics&engine=%s&song=%s", url, g_EngineName[g_Player.m_Engine], g_Player.m_Song);

#if defined DEBUG
    UTIL_DebugLog("Timer_GetLyric -> Downloading Lyrics -> %s[%s] -> %s", g_Player.m_Song, g_Player.m_Title, url);
#endif

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
    SteamWorks_SetHTTPCallbacks(hRequest, API_GetLyric_SteamWorks);
    SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 10);
    SteamWorks_SendHTTPRequest(hRequest);

    UTIL_QueueRequest(hRequest);
}

void Player_DisplayLyric()
{
    if (g_Player.m_Lyrics == null || g_Player.m_Lyrics.Length == 0)
        return;

    float fCurrent = g_Player.m_Player.PlayedSecs;
    lyric_t l;
    g_Player.m_Lyrics.GetArray(0, l, sizeof(lyric_t));
    if (fCurrent < l.m_Delay)
        return;

    g_Player.m_Lyrics.Erase(0);
    if (g_Player.m_Lyrics.Length > 0)
    {
        char words[64];
        strcopy(words, 64, l.m_Words);
        fCurrent = l.m_Delay;
        g_Player.m_Lyrics.GetArray(0, l, sizeof(lyric_t));
        
        // display lyric
        int bytes = UTIL_GetCol(words);
        float kp = l.m_Delay - fCurrent;
        float fx = (kp-0.8)/float(bytes);
        Player_LyricHud(kp, fx, words);
#if defined DEBUG
        UTIL_DebugLog("Player_DisplayLyric -> %.2f:%.2f -> %.2f:%.2f ->%s", fCurrent, l.m_Delay, fx, kp, words);
#endif
    }
    else
    {
        Player_LyricHud(10.0, 9.0, l.m_Words);
#if defined DEBUG
        UTIL_DebugLog("Player_DisplayLyric -> %.2f:%.2f ->%s", fCurrent, l.m_Delay, l.m_Words);
#endif
    }
}

void Player_LyricHud(float hold, float fx, const char[] message)
{
    // loop all client who is playing
    for(int client = 1; client <= MaxClients; ++client)
        if (IsValidClient(client) && g_bLyrics[client])
            UTIL_ShowLyric(client, message, hold, fx);

#if defined DEBUG
    UTIL_DebugLog("Player_LyricHud -> %.1f -> %.1f -> %s", hold, fx, message);
#endif
}

void Player_BroadcastMusic(int client, bool cached, const char[] url = NULL_STRING)
{
    // ban?
    if (g_bBanned[client])
    {
        Chat(client, "%T", "banned notice", client);
        return;
    }

    // if timeout 
    if (GetGameTime() < g_fNextPlay)
    {
#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> Time Out", client, g_Player.m_Song, g_Player.m_Title);
#endif
        Chat(client, "%T", "last timeout", client);
        return;
    }
    
    // get song info
    UTIL_ProcessSongInfo(client, g_Player.m_Title, g_Player.m_Artist, g_Player.m_Album, g_Player.m_Length, g_Player.m_Song, g_Player.m_Engine);

    // if enabled cache and not precache
    if (!cached)
    {
        if (g_bCaching)
        {
            Chat(client, "%T", "Global caching", client);
            return;
        }

#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> we need precache music", client, g_Player.m_Song, g_Player.m_Title);
#endif
        UTIL_CacheSong(client);
        return;
    }

    // if store is available, handle credits
    if (g_bStoreLib)
    {
        int cost = RoundFloat(g_Player.m_Length*g_Cvars.credit.FloatValue);
        if (Store_GetClientCredits(client) < cost)
        {
            Chat(client, "%T", "no enough money", client, cost);
            return;
        }
        char reason[128];
        FormatEx(reason, 128, "点歌系统点歌[%s.%s]", g_Player.m_Song, g_Player.m_Title);
        Store_SetClientCredits(client, Store_GetClientCredits(client) - cost, reason);
        Chat(client, "%T", "cost to broadcast", client, cost, g_Player.m_Title);
    }

    // set lock flag
    g_bLocked[client] = false;

#if defined DEBUG
    UTIL_DebugLog("Player_BroadcastMusic -> %N -> [%s]%s -> %.2f", client, g_Player.m_Song, g_Player.m_Title, g_Player.m_Length);
#endif

    ChatAll("%t", "broadcast", client, g_Player.m_Title, g_EngineName[g_Player.m_Engine]);
    LogToFileEx(logFile, "\"%L\" 点播了歌曲[%s - %s]", client, g_Player.m_Title,  g_Player.m_Artist);

    // set timeout
    g_fNextPlay = GetGameTime()+g_Player.m_Length+1.5;

    // play music
    int source = g_Cvars.fakeid.BoolValue ? UTIL_CreateFakeClient(g_Player.m_Title) : client;
    g_Player.m_Player = new AudioPlayer();
    g_Player.m_Player.PlayAsClient(source, url);

    // if source from real player
    if (IsValidClient(g_Player.m_Player.ClientIndex))
        AudioMixer_SetClientCanHearSelf(client, true);

#if defined DEBUG
    UTIL_DebugLog("Player_BroadcastMusic -> Prepare player from %N to %s", client, url);
#endif

    // load lyric
    Player_LoadLyric();

    for(int i = 1; i <= MaxClients; ++i)
    {
        g_bHandle[i] = false;
        g_bStopEx[i] = false;

        // ignore fakeclient and not in-game client
        if (!IsValidClient(i))
            continue;

        // ignore client who sets disabled
        if (g_bDiable[i])
        {
            SetListenOverride(i, g_Player.m_Player.ClientIndex, Listen_No);
            continue;
        }

        // otherwise
        SetListenOverride(i, g_Player.m_Player.ClientIndex, Listen_Yes);

        // handle map music
        if (g_bMapMusic)
        {
            g_bStatus[i] = MapMusic_GetStatus(i);
            MapMusic_SetStatus(i, true);
        }

#if defined DEBUG
        UTIL_DebugLog("Player_BroadcastMusic -> Handle clients -> %N", i);
#endif
    }

    CreateTimer(1.5, Timer_DisplayMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayMenu(Handle timer)
{
    for(int i = 1; i <= MaxClients; ++i)
    {
        // ignore fakeclient and not in-game client
        if (!IsValidClient(i))
            continue;

        // init player
        DisplayMainMenu(i);
    }

    return Plugin_Stop;
}

public void Event_PlayerDeath(Event e, const char[] name, bool db)
{
    if (!IsPlaying())
        return;

    int client = GetClientOfUserId(e.GetInt("userid"));
    if (!client)
        return;

    int source = g_Player.m_Player.ClientIndex;

    if (client == source)
    {
        for(int target = 1; target <= MaxClients; target++)
        if (IsValidClient(target) && !g_bStopEx[target])
        {
            // force override sv_talk
            SetListenOverride(target, source, Listen_Yes);
        }
    }
    else if (!g_bStopEx[client])
    {
        SetListenOverride(client, source, Listen_Yes);
    }
}

bool IsPlaying()
{
    return g_Player.m_Player != null && !g_Player.m_Player.IsFinished && g_Player.m_Player.PlayedSecs > 0.0;
}

bool AllowStop(int client)
{
    return !(IsPlaying() && g_Player.m_Player.ClientIndex != client);
}