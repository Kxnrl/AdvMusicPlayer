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
        if (!SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
        {
            LogError("SteamWorks -> API_SearchMusic -> WriteHTTPResponseBodyToFile failed");
            UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to search music");
        }
        else RequestFrame(UTIL_ProcessResult, userid);
    }
    else
    {
        LogError("SteamWorks -> API_SearchMusic -> HTTP Response failed: %d", eStatusCode);
        UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to search music");
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
            CreateTimer(g_cvarLRCDLY.FloatValue, UTIL_ProcessLyric);
        else LogError("SteamWorks -> API_GetLyric -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else LogError("SteamWorks -> API_GetLyric -> HTTP Response failed: %d", eStatusCode);

    delete hRequest;
}

public int API_PrepareSong_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
{
    g_fNextPlay = 0.0;
    
    if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
    {
        LogError("SteamWorks -> API_PrepareSong -> HTTP Response failed: %d", eStatusCode);
        UTIL_NotifyFailure(GetClientOfUserId(userid), "failed to precache song");
    }
    else SteamWorks_GetHTTPResponseBodyCallback(hRequest, API_CachedSong_SteamWorks, userid);

    delete hRequest;
}

public int API_CachedSong_SteamWorks(const char[] sData, int userid)
{
    int client = GetClientOfUserId(userid);
    g_bCaching = false;
    Player_BroadcastMusic(client, true, sData);
}

public int API_DownloadTranslations_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");
        if (SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path) && FileExists(path) && FileSize(path) > 2048)
            LoadTranslations("com.kxnrl.amp.translations");
        else SetFailState("SteamWorks -> API_DownloadTranslations -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else SetFailState("SteamWorks -> API_DownloadTranslations -> HTTP Response failed: %d", eStatusCode);

    delete hRequest;
}