/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          system2.sp                                     */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/

// system2 v2.6 or later

public void API_SearchMusic_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success)
    {
        char url[192];
        request.GetURL(url, 192);
        LogError("System2 -> API_SearchMusic -> Download result Error: %s -> %s", error, url);
        UTIL_NotifyFailure(GetClientOfUserId(view_as<int>(request.Any)), "failed to search music");
        return;
    }
    else if(response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_SearchMusic -> Download result Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
        UTIL_NotifyFailure(GetClientOfUserId(view_as<int>(request.Any)), "failed to search music");
        return;
    }

    RequestFrame(UTIL_ProcessResult, view_as<int>(request.Any));
}

public void API_GetLyric_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success)
    {
        char url[192];
        request.GetURL(url, 192);
        LogError("System2 -> API_GetLyric -> Download lyric Error: %s -> %s", error, url);
        return;
    }
    else if(response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_GetLyric -> Download lyric Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
        return;
    }

    DataPack pack = view_as<DataPack>(request.Any);
    int   index = pack.ReadCell();
    float delay = g_cvarLRCDLY.FloatValue - (GetGameTime() - pack.ReadFloat());
    if(delay < 0)  delay = 0.0;
    CreateTimer(delay, UTIL_ProcessLyric, index);
}

public void API_PrepareSong_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    g_fNextPlay = 0.0;
    int values = view_as<int>(request.Any);
    int userid = values &  0x7f;
    int target = values >> 7;
    int client = GetClientOfUserId(userid);

    if(!success)
    {
        char url[192];
        request.GetURL(url, 192);
        LogError("System2 -> API_CachedSong -> [%s] -> %s", error, url);
        UTIL_NotifyFailure(client, "failed to precache song");
        return;
    }

    if(response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_CachedSong -> HttpCode: %d -> %s -> %s", response.StatusCode, error, url);
        UTIL_NotifyFailure(client, "failed to precache song");
        return;
    }

    char[] output = new char[response.ContentLength+1];
    response.GetContent(output, response.ContentLength+1);

    // php echo "success!" mean preloading success. "file_exists!" mean we were precached.
    if(strcmp(output, "success!", false) == 0)
    {
        if(target == 0)
        {
            g_bCaching = false;
            Player_BroadcastMusic(client, true);
        }
        else if(IsValidClient(client))
            Player_ListenMusic(client, true);
    }
    else
    {
        UTIL_NotifyFailure(client, "failed to precache song");
        LogError("System2 -> API_CachedSong -> [%s]", output);
    }
}

public void API_DownloadTranslations_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success)
    {
        char url[192];
        request.GetURL(url, 192);
        SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: %s -> %s", error, url);
    }
    
    if(response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
    }

    char path[128];
    request.GetOutputFile(path, 128);

    if(!FileExists(path))
        SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: File does not exists!");

    if(FileSize(path) < 2048)
    {
        char content[2048];
        File file = OpenFile(path, "r+");
        ReadFileString(file, content, 2048);
        delete file;
        SetFailState("Download Translations Error: %s", content);
    }

    LoadTranslations("com.kxnrl.amp.translations");
}