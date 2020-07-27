/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          global.sp                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/27 04:52:19                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Global_CreateConVar()
{
    /* register console variables*/
    g_Cvars.Init();

    AutoExecConfig(true, "com.kxnrl.advmusicplayer");
}

void Global_CheckLibrary()
{
    // check library availavle
    g_bStoreLib = LibraryExists("store") && (GetFeatureStatus(FeatureType_Native, "Store_GetClientCredits") == FeatureStatus_Available);
    g_bMapMusic = LibraryExists("MapMusic") && (GetFeatureStatus(FeatureType_Native, "MapMusic_SetStatus") == FeatureStatus_Available);

#if defined DEBUG
    UTIL_DebugLog("Global_CheckLibrary -> g_bStoreLib -> %s", g_bStoreLib ? "Loaded" : "Failed");
    UTIL_DebugLog("Global_CheckLibrary -> g_bMapMusic -> %s", g_bMapMusic ? "Loaded" : "Failed");
#endif
}

void Global_CheckTranslations()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");

    if (FileExists(path))
    {
        if (FileSize(path) > 2048)
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
    #pragma unused path
    char url[128];
    FormatEx(url, 128, "https://build.kxnrl.com/_Raw/translations/com.kxnrl.amp.csgo.translations.txt");

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
    SteamWorks_SetHTTPRequestContextValue(hRequest, 0);
    SteamWorks_SetHTTPCallbacks(hRequest, API_DownloadTranslations_SteamWorks);
    SteamWorks_SendHTTPRequest(hRequest);
}