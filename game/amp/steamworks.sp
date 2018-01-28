/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          steamworks.sp                                  */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle   https://ump45.moe                  */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



public int API_SearchMusic_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int userid)
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

public int API_GetLyric_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int index)
{
    if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "data/music/lyric_%d.lrc", g_Sound[index][iSongId]);
        if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path))
            UTIL_ProcessLyric(index);
        else
            LogError("SteamWorks -> API_GetLyric -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else
        LogError("SteamWorks -> API_GetLyric -> HTTP Response failed: %d", eStatusCode);

    CloseHandle(hRequest);
}

public int API_PrepareSong_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int values)
{
    g_fNextPlay = 0.0;

    if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
        SteamWorks_GetHTTPResponseBodyCallback(hRequest, API_CachedSong_SteamWorks, values);
    else
        LogError("SteamWorks -> API_PrepareSong -> HTTP Response failed: %d", eStatusCode);

    CloseHandle(hRequest);
}

public int API_CachedSong_SteamWorks(const char[] sData, int values)
{
    // php echo "success!" mean preloading success. "file_exists!" mean we were precached.
    if(strcmp(sData, "success!", false) == 0 || strcmp(sData, "file_exists!", false) == 0)
    {
        int client = values & 0x7f;
        int index  = values >> 7;
        if(index == 0)
            Player_BroadcastMusic(client, true);
        else
            Player_ListenMusic(client, true);
    }
    else
        LogError("SteamWorks -> API_CachedSong -> [%s]", sData);
}


public int API_DownloadTranslations_SteamWorks(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if(!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        char path[128];
        BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");
        if(SteamWorks_WriteHTTPResponseBodyToFile(hRequest, path) && FileExists(path) && FileSize(path) > 2048)
            LoadTranslations("com.kxnrl.amp.translations");
        else
            SetFailState("SteamWorks -> API_DownloadTranslations -> SteamWorks_WriteHTTPResponseBodyToFile failed");
    }
    else
        SetFailState("SteamWorks -> API_DownloadTranslations -> HTTP Response failed: %d", eStatusCode);

    CloseHandle(hRequest);
}