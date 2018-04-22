/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          cookie.sp                                      */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Cookie_RegisterCookie()
{
    // regsiter cookies
    g_cDisable = RegClientCookie("amp_disable", "", CookieAccess_Private);
    g_cVolume  = RegClientCookie("amp_volume",  "", CookieAccess_Private);
    g_cBanned  = RegClientCookie("amp_banned",  "", CookieAccess_Private);
    g_cBGMVol  = RegClientCookie("amp_bgmvol",  "", CookieAccess_Private);
    g_cLyrics  = RegClientCookie("amp_lyrics",  "", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
    // load cookies
    char buf[5][4];
    GetClientCookie(client, g_cDisable, buf[0], 4);
    GetClientCookie(client, g_cVolume,  buf[1], 4);
    GetClientCookie(client, g_cBanned,  buf[2], 4);
    GetClientCookie(client, g_cBGMVol,  buf[3], 4);
    GetClientCookie(client, g_cLyrics,  buf[4], 4);

    // processing cookies
    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_iVolume[client] = (StringToInt(buf[1]) >= 10) ? StringToInt(buf[1]) : 65;
    g_bBanned[client] = (StringToInt(buf[2]) ==  1);
    g_iBGMVol[client] = (strlen(buf[3]) > 0) ? StringToInt(buf[3]) : 100;
    g_bLyrics[client] = (StringToInt(buf[4]) != 1);

    // processing map music
    if(g_bMapMusic)
        MapMusic_SetVolume(client, g_iBGMVol[client]);
    
#if defined DEBUG
    UTIL_DebugLog("OnClientCookiesCached -> %N -> %s | %s | %s | %s | %s", client, buf[0], buf[1], buf[2], buf[3], buf[4]);
#endif
}