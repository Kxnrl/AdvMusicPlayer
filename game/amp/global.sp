/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          global.sp                                      */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
/*                                                                */
/******************************************************************/



void Global_CreateConVar()
{
    /* register console variables*/

    // url
    g_cvarSEARCH = CreateConVar("amp_url_search", "https://api.kxnrl.com/music/search.php?sc=", "url for searching music.");
    g_cvarLYRICS = CreateConVar("amp_url_lyrics", "https://api.kxnrl.com/music/lyrics.php?id=", "url for downloading lyric.");
    g_cvarPLAYER = CreateConVar("amp_url_player", "https://api.kxnrl.com/music/player.php?id=", "url of motd player.");
    g_cvarCACHED = CreateConVar("amp_url_cached", "https://api.kxnrl.com/music/cached.php?id=", "url for caching music. (caching songs are not allowed in api.kxnrl.com)");

    // others
    g_cvarECACHE = CreateConVar("amp_url_cached_enable",   "0",   "enable music cached in your web server (0 = disabled, 1 = enabled). In some areas, player can not connect to music server directly. use ur web server to cache music", _, true, 0.0, true, 1.0);
    g_cvarCREDIT = CreateConVar("amp_cost_factor",         "2.0", "how much for broadcasting song (if store is availavle). song length(sec) * this value = cost credits.", _, true, 0.000001, true, 100000.0);

    AutoExecConfig(true, "com.kxnrl.advmusicplayer");
}

void Global_CheckLibrary()
{
    // check library availavle
    g_bStoreLib = LibraryExists("store") && (GetFeatureStatus(FeatureType_Native, "Store_GetClientCredits") == FeatureStatus_Available);
    g_bMapMusic = LibraryExists("MapMusic") && (GetFeatureStatus(FeatureType_Native, "MapMusic_SetStatus") == FeatureStatus_Available);
    g_bSystem2 = LibraryExists("system2");
    if(!g_bSystem2 && GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") != FeatureStatus_Available)
        SetFailState("Why you not install System2 or SteamWorks?");
    
#if defined DEBUG
    UTIL_DebugLog("Global_CheckLibrary -> g_bStoreLib -> %s", g_bStoreLib ? "Loaded" : "Failed");
    UTIL_DebugLog("Global_CheckLibrary -> g_bMapMusic -> %s", g_bMapMusic ? "Loaded" : "Failed");
    UTIL_DebugLog("Global_CheckLibrary -> g_bSystem2 -> %s", g_bSystem2 ? "Loaded" : "Failed");
#endif
}

void Global_CheckTranslations()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");

    if(FileExists(path))
    {
        if(FileSize(path) > 2048)
        {
            LoadTranslations("com.kxnrl.amp.translations");
            return;
        }
        else DeleteFile(path);
    }

    Global_CheckLibrary();
    Global_DownloadTranslations(path);
}

void Global_DownloadTranslations(const char[] path)
{
    char url[128];
    FormatEx(url, 128, "https://github.com/Kxnrl/AdvMusicPlayer/raw/master/game/com.kxnrl.amp.translations.txt");

    if(g_bSystem2)
    {
        System2HTTPRequest hRequest = new System2HTTPRequest(API_DownloadTranslations_System2, url);
        hRequest.SetOutputFile(path);
        hRequest.GET();
        delete hRequest;
    }
    else
    {
        Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPRequestContextValue(hRequest, 0);
        SteamWorks_SetHTTPCallbacks(hRequest, API_DownloadTranslations_SteamWorks);
        SteamWorks_SendHTTPRequest(hRequest);
        delete hRequest;
    }
}