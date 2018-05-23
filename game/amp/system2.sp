/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          system2.sp                                     */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
/*                                                                */
/******************************************************************/

// system2 v2.6 or later

public void API_SearchMusic_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success || response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_SearchMusic -> Download result Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
        return;
    }

    UTIL_ProcessResult(view_as<int>(request.Any));
}

public void API_GetLyric_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success || response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_GetLyric -> Download lyric Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
        return;
    }

    UTIL_ProcessLyric(view_as<int>(request.Any));
}

public void API_PrepareSong_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    g_fNextPlay = 0.0;
    
    if(!success)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_CachedSong -> [%s] -> %s", error, url);
    }
    else if(response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        LogError("System2 -> API_CachedSong -> HttpCode: %d -> %s -> %s", response.StatusCode, error, url);
    }
    else
    {
        char[] output = new char[response.ContentLength+1];
        response.GetContent(output, response.ContentLength+1);

        // php echo "success!" mean preloading success. "file_exists!" mean we were precached.
        if(strcmp(output, "success!", false) == 0 || strcmp(output, "file_exists!", false) == 0)
        {
            int values = view_as<int>(request.Any);
            int client = values & 0x7f;
            int target  = values >> 7;
            if(target == 0)
                Player_BroadcastMusic(client, true);
            else
                Player_ListenMusic(client, true);
        }
        else
            LogError("System2 -> API_CachedSong -> [%s]", output);
    }
}

public void API_DownloadTranslations_System2(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method)
{
    if(!success || response.StatusCode != 200)
    {
        char url[192];
        response.GetLastURL(url, 192);
        SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: %s -> HttpCode: %d -> %s", error, response.StatusCode, url);
    }

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