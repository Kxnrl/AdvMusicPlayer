/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          steamworks.sp                                  */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/27 04:52:19                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



public int API_SearchMusic_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/search_%d.kv", userid);
#if defined DEBUG
        UTIL_DebugLog("API_SearchMusic_SteamWorks -> Success -> %d -> %s", userid, path);
#endif
        if (!SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
        {
            LogError("SteamWorks -> API_SearchMusic -> WriteHTTPResponseBodyToFile failed");
            UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to search music", true);
        }
        else RequestFrame(UTIL_ProcessResult, userid);
    }
    else
    {
        LogError("SteamWorks -> API_SearchMusic -> HTTP Response failed: %d", eStatusCode);
        UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to search music", true);
    }

    delete hRequest;
}

public int API_GetLyric_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/lyric_%s_%s.lrc", g_EngineName[g_Player.m_Engine], g_Player.m_Song);
        if (SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
            CreateTimer(g_Cvars.lyrics.FloatValue, UTIL_ProcessLyric);
        else LogError("SteamWorks -> API_GetLyric -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else LogError("SteamWorks -> API_GetLyric -> HTTP Response failed: %d", eStatusCode);

    UTIL_EraseRequest(hRequest);
}

public int API_PrepareSong_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    g_fNextPlay = GetGameTime() + 15.0;
    
    if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
    {
        LogError("SteamWorks -> API_PrepareSong -> HTTP Response failed: %d", eStatusCode);
        g_bCaching = false;
        UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to precache song", true);
    }
    else
    {
#if defined DEBUG
        UTIL_DebugLog("API_PrepareSong_SteamWorks -> success");
#endif
        SteamWorks_GetHTTPResponseBodyCallback(hRequest, API_CachedSong_SteamWorks, userid);
        UTIL_EraseRequest(hRequest);
    }
}

public int API_CachedSong_SteamWorks(const char[] sData, int userid)
{
#if defined DEBUG
        UTIL_DebugLog("API_CachedSong_SteamWorks -> %d -> %s", userid, sData);
#endif

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/sound_%s_%s.mp3", g_EngineName[g_Player.m_Engine], g_Player.m_Song);
    if (FileExists(path))
    {
        g_bCaching = false;
        g_fNextPlay = 0.0;
        Format(path, 128, "csgo/%s", path);
        Player_BroadcastMusic(GetClientOfUserId(userid), true, path);
        return;
    }

#if defined DEBUG
    UTIL_DebugLog("API_CachedSong_SteamWorks -> try to download song from %s", sData);
#endif

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sData);
    SteamWorks_SetHTTPRequestContextValue(hRequest, userid);
    SteamWorks_SetHTTPCallbacks(hRequest, API_DownloadSound_SteamWorks);
    SteamWorks_SendHTTPRequest(hRequest);

    UTIL_QueueRequest(hRequest);
}

public int API_DownloadSound_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    g_fNextPlay = GetGameTime() + 5.0;

#if defined DEBUG
    UTIL_DebugLog("API_DownloadSound_SteamWorks -> finished.");
#endif

    if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
    {
        LogError("SteamWorks -> API_DownloadSound_SteamWorks -> HTTP Response failed: %d", eStatusCode);
        UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to precache song", true);
    }
    else
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/sound_%s_%s.mp3", g_EngineName[g_Player.m_Engine], g_Player.m_Song);
        if (SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
        {
            g_bCaching = false;
            g_fNextPlay = 0.0;
            Format(path, 128, "csgo/%s", path);
            Player_BroadcastMusic(GetClientOfUserId(userid), true, path);
        }
        else
        {
            LogError("SteamWorks -> API_DownloadSound_SteamWorks -> SteamWorks_WriteHTTPResponseBodyToFile failed");
            UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to precache song", true);
        }

        UTIL_EraseRequest(hRequest);
    }
}

public int API_DownloadTranslations_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");
        if (SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path) && FileExists(path) && FileSize(path) > 2048)
        {
            LoadTranslations("com.kxnrl.amp.translations");
            ServerCommand("sm_reload_translations");
        }
        else SetFailState("SteamWorks -> API_DownloadTranslations -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else SetFailState("SteamWorks -> API_DownloadTranslations -> HTTP Response failed: %d", eStatusCode);

    delete hRequest;
}