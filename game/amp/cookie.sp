/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          cookie.sp                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/27 04:52:19                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Cookie_RegisterCookie()
{
    if (!LibraryExists("clientprefs"))
        return;

    // regsiter cookies
    g_cDisable = RegClientCookie("amp_disable", "", CookieAccess_Private);
    g_cBanned  = RegClientCookie("amp_banned",  "", CookieAccess_Private);
    g_cLyrics  = RegClientCookie("amp_lyrics",  "", CookieAccess_Private);
}

void Cookies_OnClientLoad(int client)
{
    if (!LibraryExists("clientprefs")|| !AreClientCookiesCached(client))
        return;

    OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
    // load cookies
    char buf[3][4];
    GetClientCookie(client, g_cDisable, buf[0], 4);
    GetClientCookie(client, g_cBanned,  buf[1], 4);
    GetClientCookie(client, g_cLyrics,  buf[2], 4);

    // processing cookies
    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_bBanned[client] = (StringToInt(buf[1]) ==  1);
    g_bLyrics[client] = (StringToInt(buf[2]) !=  1);

#if defined DEBUG
    UTIL_DebugLog("OnClientCookiesCached -> %N -> %s | %s | %s", client, buf[0], buf[1], buf[2]);
#endif
}

void Cookie_SetValue(int client, Handle cookie, const char[] value)
{
    if (!LibraryExists("clientprefs"))
        return;

    SetClientCookie(client, cookie, value);
}