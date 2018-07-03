/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          cookie.sp                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
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
    g_cLyrics  = RegClientCookie("amp_lyrics",  "", CookieAccess_Private);
}

public void OnClientCookiesCached(int client)
{
    // load cookies
    char buf[4][4];
    GetClientCookie(client, g_cDisable, buf[0], 4);
    GetClientCookie(client, g_cVolume,  buf[1], 4);
    GetClientCookie(client, g_cBanned,  buf[2], 4);
    GetClientCookie(client, g_cLyrics,  buf[3], 4);

    // processing cookies
    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_iVolume[client] = (StringToInt(buf[1]) >= 10) ? StringToInt(buf[1]) : 65;
    g_bBanned[client] = (StringToInt(buf[2]) ==  1);
    g_bLyrics[client] = (StringToInt(buf[3]) !=  1);

#if defined DEBUG
    UTIL_DebugLog("OnClientCookiesCached -> %N -> %s | %s | %s | %s", client, buf[0], buf[1], buf[2], buf[3]);
#endif
}