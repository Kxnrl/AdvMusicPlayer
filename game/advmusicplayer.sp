/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          advmusicplayer.sp                              */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/27 04:52:19                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/


// compiler stuff
#pragma semicolon 1
#pragma newdecls required

// VERSION
#define PI_VERSION "3.1.<commit_count>"

// DEBUG?
//#define DEBUG

#include <sourcemod>

// Require Extensions
#include <steamworks>
#include <audio>
#include <sdktools_voice>
#include <sdktools_functions>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

// Store library
#undef REQUIRE_PLUGIN
#include <store>
#define REQUIRE_PLUGIN

// MapMusic library
#undef REQUIRE_PLUGIN
#include <mapmusic>
#include <fys.opts>
#include <fys.pupd>
#define REQUIRE_PLUGIN

// other stuff
#define MAXINDEX MAXPLAYERS+1

// global variables
float g_fNextPlay;
bool g_bMapMusic;
bool g_bStoreLib;
bool g_bCaching;

// Console variables
enum struct cvars_t
{
    ConVar apiurl;
    ConVar lyrics;
    ConVar limits;
    ConVar credit;
    ConVar fakeid;

    void Init()
    {
        this.apiurl = CreateConVar("amp_api_engine",   "https://music.kxnrl.com/api/v4",   "Url for music engine API. (DON'T CHANGE THIS IF YOU DON'T KNOW WHAT YOU DO, IF NOT WORKING, CHANGE TO DEFAULT VALUE)");
        this.lyrics = CreateConVar("amp_lrc_delay",    "0.5",                              "How many second(s) delay to display lyric on lyric loaded.",                                              _, true, 0.0, true, 10.0);
        this.limits = CreateConVar("amp_mnt_search",    "20",                              "How many songs will display in once search.",                                                             _, true, 5.0, true, 60.0);
        this.credit = CreateConVar("amp_cost_factor",  "2.0",                              "How much for broadcasting song (if store is availavle). song length(sec) * this value = cost credits.",   _, true, 0.1, true, 99.0);
        this.fakeid = CreateConVar("amp_player_fake",    "1",                              "If true, play sound from GOTV or fake client, from player index otherwise.",                              _, true, 0.0, true,  1.0);
    }
}
cvars_t g_Cvars;

// client variables
bool    g_bStatus[MAXINDEX];
bool    g_bLyrics[MAXINDEX];
bool    g_bDiable[MAXINDEX];
bool    g_bBanned[MAXINDEX];
bool    g_bHandle[MAXINDEX];
bool    g_bLocked[MAXINDEX];
bool    g_bStopEx[MAXINDEX];
int     g_iSelect[MAXINDEX];
kEngine g_kEngine[MAXINDEX];

// Music Engine 
enum kEngine
{
    kE_Netease,
    kE_Tencent,
    kE_XiaMi,
    kE_KuGou,
    kE_Baidu,
    kE_Custom
};

enum struct lyric_t
{
    char m_Words[64];
    float m_Delay;
}

enum struct music_t
{
    char m_Song[32];
    char m_Title[64];
    char m_Artist[64];
    char m_Album[64];
    char m_Mp3Uri[256];
    float m_Length;
    kEngine m_Engine;
    ArrayList m_Lyrics;
    AudioPlayer m_Player;
    ArrayList m_Request;

    void Reset()
    {
        this.m_Song[0] = '\0';
        this.m_Title[0] = '\0';
        this.m_Artist[0] = '\0';
        this.m_Album[0] = '\0';
        this.m_Mp3Uri[0] = '\0';
        this.m_Length = 0.0;

        if (this.m_Lyrics != null)
        {
            delete this.m_Lyrics;
            this.m_Lyrics  = null;
        }

        if (this.m_Player != null)
        {
            for (int client = 1; client <= MaxClients; client++)
            if (IsValidClient(client))
            SetListenOverride(client, this.m_Player.ClientIndex, Listen_Default);

            if (IsValidClient(this.m_Player.ClientIndex))
                AudioMixer_SetClientCanHearSelf(this.m_Player.ClientIndex, false);
            else if (this.m_Player.ClientIndex != 1) // ignore GOTV?
                KickClient(this.m_Player.ClientIndex, "Reset Player");

            delete this.m_Player;
            this.m_Player  = null;
        }

        // close all steamworks handle
        while (this.m_Request.Length > 0)
        {
            Handle request = this.m_Request.Get(0);
            delete request;
            this.m_Request.Erase(0);
        }
    }
}

char g_EngineName[][] = {"netease", "tencent", "xiami", "kugou", "baidu", "custom"};

music_t g_Player;

// cookies
enum opts_ref
{
    Opts_Enable,
    Opts_Banned,
    Opts_Lyrics
}
enum struct opts_t
{
    Handle enable;
    Handle banned;
    Handle lyrics;

    void Init()
    {
        this.enable = RegClientCookie("amp_disable", "", CookieAccess_Private);
        this.banned = RegClientCookie("amp_banned",  "", CookieAccess_Private);
        this.lyrics = RegClientCookie("amp_lyrics",  "", CookieAccess_Private);
    }
}
opts_t g_Cookie;

// logging
char logFile[128];

// files
#include "amp/command.sp"
#include "amp/cookie.sp"
#include "amp/global.sp"
#include "amp/menu.sp"
#include "amp/utils.sp"
#include "amp/player.sp"
#include "amp/steamworks.sp"


public Plugin myinfo = 
{
    name        = "Advanced Music Player",
    author      = "Kyle",
    description = "Media System",
    version     = PI_VERSION,
    url         = "https://music.kxnrl.com/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Store
    MarkNativeAsOptional("Store_GetClientCredits");
    MarkNativeAsOptional("Store_SetClientCredits");

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
        if (IsValidClient(client))
        {
            OnClientConnected(client);
            Cookies_OnClientLoad(client);
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
    Cookies_CheckLibrary();
}

public void OnLibraryRemoved(const char[] name)
{
    // Fire to modules
    Global_CheckLibrary();
    Cookies_CheckLibrary();
}

public void OnMapEnd()
{
    // Reset broadcast
    Player_Reset();
}

public void OnClientConnected(int client)
{
    // Reset client
    g_bDiable[client] = false;
    g_bBanned[client] = false;
    g_bHandle[client] = false;
    g_bStopEx[client] = false;
    g_bLocked[client] = false;
    g_bLyrics[client] = true;

#if defined DEBUG
    UTIL_DebugLog("OnClientConnected -> Init %N", client);
#endif
}

public void OnClientDisconnect(int client)
{
    if (g_Player.m_Player == null)
        return;

    if (g_Player.m_Player.ClientIndex != client)
        return;

    Player_Reset();
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
    if (SayText2 == null)
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
        if (IsValidClient(client))
        {
            SetGlobalTransTarget(client);

            VFormat(msg, 256, chat, 2);
            Format(msg, 256, "[\x10AMP\x01]   %s", msg);
            ProcessColorString(msg, 256);

            Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
            if (SayText2 == null)
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