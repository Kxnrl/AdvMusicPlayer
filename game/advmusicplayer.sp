/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          advmusicplayer.sp                              */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle   https://ump45.moe                  */
/*  2017/12/30 17:36:14                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



// DEBUG?
#define DEBUG

// Require Extensions (System2 or SteamWorks)
#undef REQUIRE_EXTENSIONS
#include <system2>
#include <steamworks>
#define REQUIRE_EXTENSIONS

// Cookies
#include <clientprefs>

// CG library
#undef REQUIRE_PLUGIN
#include <cg_core>
#include <store>
#define REQUIRE_PLUGIN

// MapMusic library
#undef REQUIRE_PLUGIN
#include <mapmusic>
#define REQUIRE_PLUGIN

// MotdEx library
#undef REQUIRE_PLUGIN
#include <motdex>
#define REQUIRE_PLUGIN

// other stuff
#define PREFIX            "[\x10Music\x01]  "
#define logFile           "addons/sourcemod/logs/advmusicplayer.log"
#define BROADCAST         0

// compiler stuff
#pragma semicolon 1
#pragma newdecls required

// global variables
float g_fNextPlay;
bool g_bMotdEx;
bool g_bMapMusic;
bool g_bSystem2;
bool g_bCoreLib;
bool g_bStoreLib;

// convar values
int g_iEnableProxy = 0;
int g_iEnableCache = 0;
float g_fFactorCredits = 2.0;
char g_urlSearch[192] = "https://csgogamers.com/musicserver/api/search.php?s=";
char g_urlLyrics[192] = "https://csgogamers.com/musicserver/api/lyrics.php?id=";
char g_urlPlayer[192] = "https://csgogamers.com/musicserver/api/player.php?id=";
char g_urlCached[192] = "https://csgogamers.com/musicserver/api/cached.php?id=";

// client variables
bool g_bLyrics[MAXPLAYERS+1];
bool g_bDiable[MAXPLAYERS+1];
bool g_bBanned[MAXPLAYERS+1];
bool g_bHandle[MAXPLAYERS+1];
bool g_bPlayed[MAXPLAYERS+1];
bool g_bListen[MAXPLAYERS+1];
int  g_iVolume[MAXPLAYERS+1];
int  g_iBGMVol[MAXPLAYERS+1];
int  g_iSelect[MAXPLAYERS+1];
Handle g_tTimer[MAXPLAYERS+1];

// enum type
enum songinfo
{
    iSongId,
    String:szName[128],
    String:szSinger[64],
    String:szAlbum[64],
    Float:fLength
}
songinfo g_Sound[MAXPLAYERS+1][songinfo];

// cookies
Handle g_cDisable;
Handle g_cVolume;
Handle g_cBanned;
Handle g_cBGMVol;
Handle g_cLyrics;

// lyric array
ArrayList array_timer[MAXPLAYERS+1];
ArrayList array_lyric[MAXPLAYERS+1];

// files
#include "amp/command.sp"
#include "amp/cookie.sp"
#include "amp/global.sp"
#include "amp/menu.sp"
#include "amp/utils.sp"
#include "amp/player.sp"
#include "amp/steamworks.sp"
#include "amp/system2.sp"


public Plugin myinfo = 
{
    name        = "Advanced Music Player",
    author      = "Kyle",
    description = "Media System , Powered by CG Community",
    version     = "2.0.<commit_count>.<commit_branch> - <commit_date>",
    url         = "https://ump45.moe"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // CG
    MarkNativeAsOptional("CG_ShowHiddenMotd");
    MarkNativeAsOptional("CG_RemoveMotd");
    MarkNativeAsOptional("CG_ShowGameText");
    MarkNativeAsOptional("CG_ShowGameTextToClient");
    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");
    
    // System2
    MarkNativeAsOptional("System2_GetPage");
    MarkNativeAsOptional("System2_DownloadFile");
    
    // SteamWorks
    MarkNativeAsOptional("SteamWorks_CreateHTTPRequest");
    MarkNativeAsOptional("SteamWorks_SetHTTPRequestContextValue");
    MarkNativeAsOptional("SteamWorks_SetHTTPCallbacks");
    MarkNativeAsOptional("SteamWorks_SendHTTPRequest");
    MarkNativeAsOptional("SteamWorks_WriteHTTPResponseBodyToFile");
    MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodyCallback");
    
    // MotdEx
    MarkNativeAsOptional("MotdEx_ShowHiddenMotd");
    MarkNativeAsOptional("MotdEx_RemoveMotd");
    
    // MapMusic
    MarkNativeAsOptional("MapMusic_SetStatus");
    MarkNativeAsOptional("MapMusic_SetVolume");

    return APLRes_Success;
}

public void OnPluginStart()
{
    // Create a director to save files
    UTIL_CheckDirector();

    // Fire to modules
    Cookie_RegisterCookie();
    Command_CreateCommand();
    Player_InitPlayer();

    // We need check all client
    for(int client = 1; client <= MaxClients; ++client)
        if(IsValidClient(client))
        {
            OnClientConnected(client);
            if(AreClientCookiesCached(client))
                OnClientCookiesCached(client);
        }
}

public void OnAllPluginsLoaded()
{
    // Fire to modules
    Global_CreateConVar();
    Global_CheckLibrary();
}

public void OnLibraryAdded(const char[] name)
{
    // Fire to modules
    Global_CheckLibrary();
}

public void OnLibraryRemoved(const char[] name)
{
    // Fire to modules
    Global_CheckLibrary();
}

public void OnMapEnd()
{
    // Reset broadcast
    Player_Reset(BROADCAST);
}

public void OnClientConnected(int client)
{
    // Reset client
    g_bPlayed[client] = false;
    g_bListen[client] = false;
    g_bDiable[client] = false;
    g_bBanned[client] = false;
    g_bHandle[client] = false;
    g_bLyrics[client] = true;
    g_iVolume[client] = 100;
    g_iBGMVol[client] = 100;
}

public void OnClientDisconnect(int client)
{
    // Reset client`s player
    Player_Reset(client);
}

bool IsValidClient(int client)
{
    // valid client
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);
	return AddMenuItem(menu, info, m_szBuffer, style);
}