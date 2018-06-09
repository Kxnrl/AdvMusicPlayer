/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          advmusicplayer.sp                              */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 17:36:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



// DEBUG?
//#define DEBUG

// Require Extensions (System2 or SteamWorks)
#undef REQUIRE_EXTENSIONS
#include <system2>
#include <steamworks>
#define REQUIRE_EXTENSIONS

// Cookies
#include <clientprefs>

// Store library
#undef REQUIRE_PLUGIN
#include <store>
#define REQUIRE_PLUGIN

// MapMusic library
#undef REQUIRE_PLUGIN
#include <mapmusic>
#define REQUIRE_PLUGIN

// other stuff
#define logFile           "addons/sourcemod/logs/advmusicplayer.log"
#define BROADCAST         0

// compiler stuff
#pragma semicolon 1
#pragma newdecls required

// global variables
float g_fNextPlay;
bool g_bMapMusic;
bool g_bSystem2;
bool g_bStoreLib;

// Console variables
ConVar g_cvarSEARCH;
ConVar g_cvarLYRICS;
ConVar g_cvarPLAYER;
ConVar g_cvarCACHED;
ConVar g_cvarECACHE;
ConVar g_cvarCREDIT;

// client variables
bool g_bStatus[MAXPLAYERS+1];
bool g_bLyrics[MAXPLAYERS+1];
bool g_bDiable[MAXPLAYERS+1];
bool g_bBanned[MAXPLAYERS+1];
bool g_bHandle[MAXPLAYERS+1];
bool g_bPlayed[MAXPLAYERS+1];
bool g_bListen[MAXPLAYERS+1];
int  g_iVolume[MAXPLAYERS+1];
int  g_iSelect[MAXPLAYERS+1];
Handle g_tTimer[MAXPLAYERS+1];

// enum songinfo
enum songinfo
{
    iSongId,
    String:szName[128],
    String:szSinger[64],
    String:szAlbum[64],
    Float:fLength
}
any g_Sound[MAXPLAYERS+1][songinfo];

// cookies
Handle g_cDisable;
Handle g_cVolume;
Handle g_cBanned;
Handle g_cLyrics;

// lyric array
ArrayList array_timer[MAXPLAYERS+1];
ArrayList array_lyric[MAXPLAYERS+1];
float delay_lyric[MAXPLAYERS+1][128];

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
    description = "Media System",
    version     = "2.2.<commit_count>",
    url         = "https://kxnrl.com"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Store
    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");

    // System2
    MarkNativeAsOptional("System2HTTPRequest.System2HTTPRequest");
    MarkNativeAsOptional("System2HTTPRequest.GET");
    MarkNativeAsOptional("System2Request.SetOutputFile");
    MarkNativeAsOptional("System2Request.GetOutputFile");
    MarkNativeAsOptional("System2Request.Any.get");
    MarkNativeAsOptional("System2Request.Any.set");
    MarkNativeAsOptional("System2Request.GetURL");
    MarkNativeAsOptional("System2Response.StatusCode.get");
    MarkNativeAsOptional("System2Response.GetLastURL");

    // SteamWorks
    MarkNativeAsOptional("SteamWorks_CreateHTTPRequest");
    MarkNativeAsOptional("SteamWorks_SetHTTPRequestContextValue");
    MarkNativeAsOptional("SteamWorks_SetHTTPCallbacks");
    MarkNativeAsOptional("SteamWorks_SendHTTPRequest");
    MarkNativeAsOptional("SteamWorks_WriteHTTPResponseBodyToFile");
    MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodyCallback");

    // MapMusic
    MarkNativeAsOptional("MapMusic_SetStatus");
    MarkNativeAsOptional("MapMusic_GetStatus");
    MarkNativeAsOptional("MapMusic_SetVolume");
    MarkNativeAsOptional("MapMusic_GetVolume");

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
    Global_CheckTranslations();

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

#if defined DEBUG
    UTIL_DebugLog("OnClientConnected -> Init %N", client);
#endif
}

public void OnClientDisconnect(int client)
{
    // Reset client`s player
    Player_Reset(client);
}

bool IsValidClient(int client)
{
    // valid client
    return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client));
}

bool AddMenuItemEx(Menu menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);
	return menu.AddItem(info, m_szBuffer, style);
}

void Chat(int client, const char[] chat, any ...)
{
    Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if(SayText2 == null)
    {
        LogError("StartMessageOne -> SayText2 is null");
        return;
    }

    char msg[256];
    VFormat(msg, 256, chat, 3);
    Format(msg, 256, "[\x10AMP\x01]   %s", msg);
    ProcessColorString(msg, 256);
    SayText2.SetInt("ent_idx", 0);
    SayText2.SetBool("chat", false);
    SayText2.SetString("msg_name", msg);
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    EndMessage();
}

void ChatAll(const char[] chat, any ...)
{
    char msg[256];
    for(int client = 1; client <= MaxClients; ++client)
        if(IsValidClient(client))
        {
            SetGlobalTransTarget(client);

            VFormat(msg, 256, chat, 2);
            Format(msg, 256, "[\x10AMP\x01]   %s", msg);
            ProcessColorString(msg, 256);

            Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if(SayText2 == null)
            {
                LogError("StartMessageOne -> SayText2 is null");
                continue;
            }

            SayText2.SetInt("ent_idx", 0);
            SayText2.SetBool("chat", false);
            SayText2.SetString("msg_name", msg);
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            SayText2.AddString("params", "");
            EndMessage();
        }

    SetGlobalTransTarget(LANG_SERVER);
}

static void ProcessColorString(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{normal}",      "\x01", false);
    ReplaceString(message, maxLen, "{default}",     "\x01", false);
    ReplaceString(message, maxLen, "{white}",       "\x01", false);
    ReplaceString(message, maxLen, "{darkred}",     "\x02", false);
    ReplaceString(message, maxLen, "{pink}",        "\x03", false);
    ReplaceString(message, maxLen, "{green}",       "\x04", false);
    ReplaceString(message, maxLen, "{lime}",        "\x05", false);
    ReplaceString(message, maxLen, "{yellow}",      "\x05", false);
    ReplaceString(message, maxLen, "{lightgreen}",  "\x06", false);
    ReplaceString(message, maxLen, "{lightred}",    "\x07", false);
    ReplaceString(message, maxLen, "{red}",         "\x07", false);
    ReplaceString(message, maxLen, "{gray}",        "\x08", false);
    ReplaceString(message, maxLen, "{grey}",        "\x08", false);
    ReplaceString(message, maxLen, "{olive}",       "\x09", false);
    ReplaceString(message, maxLen, "{orange}",      "\x10", false);
    ReplaceString(message, maxLen, "{silver}",      "\x0A", false);
    ReplaceString(message, maxLen, "{lightblue}",   "\x0B", false);
    ReplaceString(message, maxLen, "{blue}",        "\x0C", false);
    ReplaceString(message, maxLen, "{purple}",      "\x0E", false);
    ReplaceString(message, maxLen, "{darkorange}",  "\x0F", false);
}