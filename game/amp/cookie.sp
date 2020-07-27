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

static bool bClps;
static bool bOpts;

void Cookie_RegisterCookie()
{
    if (!LibraryExists("clientprefs"))
        return;

    // regsiter cookies
    g_Cookie.Init();
}

void Cookies_CheckLibrary()
{
    bClps = LibraryExists("clientprefs");
    bOpts = LibraryExists("fys-Opts");
}

void Cookies_OnClientLoad(int client)
{
    if (bOpts && Opts_IsClientLoaded(client))
    {
        Opts_OnClientLoad(client);
    }
    else if (bClps && AreClientCookiesCached(client))
    {
        OnClientCookiesCached(client);
    }
}

public void Opts_OnClientLoad(int client)
{
    g_bDiable[client] = Opts_GetOptBool(client, Cookie_RefToOptsName(Opts_Enable), false);
    g_bBanned[client] = Opts_GetOptBool(client, Cookie_RefToOptsName(Opts_Banned), false);
    g_bLyrics[client] = Opts_GetOptBool(client, Cookie_RefToOptsName(Opts_Lyrics), true);
}

public void OnClientCookiesCached(int client)
{
    // load cookies
    char buf[3][4];
    GetClientCookie(client, g_Cookie.enable, buf[0], 4);
    GetClientCookie(client, g_Cookie.banned, buf[1], 4);
    GetClientCookie(client, g_Cookie.lyrics, buf[2], 4);

    // processing cookies
    g_bDiable[client] = (StringToInt(buf[0]) ==  1);
    g_bBanned[client] = (StringToInt(buf[1]) ==  1);
    g_bLyrics[client] = (StringToInt(buf[2]) !=  1);

#if defined DEBUG
    UTIL_DebugLog("OnClientCookiesCached -> %N -> %s | %s | %s", client, buf[0], buf[1], buf[2]);
#endif
}

void Cookie_SetValue(int client, opts_ref ref, bool value)
{
    if (bOpts)
    {
        Opts_SetOptBool(client, Cookie_RefToOptsName(ref), value);
    }
    else if (bClps)
    {
        SetClientCookie(client, Cookie_RefToHandle(ref), value ? "1" : "0");
    }
}

static char[] Cookie_RefToOptsName(opts_ref ref)
{
    char buffer[16];
    switch (ref)
    {
        case Opts_Enable: strcopy(buffer, 16, "AMP.Opts.Enable");
        case Opts_Banned: strcopy(buffer, 16, "AMP.Opts.Banned");
        case Opts_Lyrics: strcopy(buffer, 16, "AMP.Opts.Lyrics");
    }

    return buffer;
}

static Handle Cookie_RefToHandle(opts_ref ref)
{
    switch (ref)
    {
        case Opts_Enable: return g_Cookie.enable;
        case Opts_Banned: return g_Cookie.banned;
        case Opts_Lyrics: return g_Cookie.lyrics;
    }

    return null;
}