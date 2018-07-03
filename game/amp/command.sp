/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          command.sp                                     */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void Command_CreateCommand()
{
    // console command
    RegConsoleCmd("sm_music",        Command_Music);
    RegConsoleCmd("sm_dj",           Command_Music);
    RegConsoleCmd("sm_media",        Command_Music);

    // admin command
    RegAdminCmd("sm_adminmusicstop", Command_AdminStop, ADMFLAG_BAN);
    RegAdminCmd("sm_musicban",       Command_MusicBan,  ADMFLAG_BAN);
}

public Action Command_Music(int client, int args)
{
    // ignore console
    if(!IsValidClient(client))
        return Plugin_Handled;

#if defined DEBUG
    UTIL_DebugLog("Command_Music -> %N", client);
#endif

    // display main menu to client
    DisplayMainMenu(client);

    return Plugin_Handled;
}

public Action Command_AdminStop(int client, int args)
{

#if defined DEBUG
    UTIL_DebugLog("Command_Music -> %N", client);
#endif

    // notify sound end
    CreateTimer(0.1, Timer_SoundEnd, BROADCAST);
    ChatAll("%t", "admin force stop");

    return Plugin_Handled;
}

public Action Command_MusicBan(int client, int args)
{
    // args: sm_musicban <client SteamId|UserId>
    if(args < 1)
        return Plugin_Handled;

    char buffer[16];
    GetCmdArg(1, buffer, 16);
    int target = FindTarget(client, buffer, true);

    // valid target?
    if(!IsValidClient(target))
        return Plugin_Handled;

    // processing ban
    g_bBanned[target] = !g_bBanned[target];
    SetClientCookie(target, g_cBanned, g_bBanned[target] ? "1" : "0");
    ChatAll("%t", "music ban chat", target, g_bBanned[target] ? "BAN" : "UNBAN");
    
#if defined DEBUG
    UTIL_DebugLog("Command_MusicBan -> \"%L\" %s \"%N\"", client, g_bBanned[target] ? "BAN" : "UNBAN", target);
#endif

    return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    // ignore console and not handing client
    if(!client || !g_bHandle[client])
        return Plugin_Continue;

    g_bHandle[client] = false;

    // ToDo: will add tencent QQ music
    Chat(client, "%T", "searching", client, g_EngineName[g_kEngine[client]], client);

    char url[256];
    g_cvarAPIURL.GetString(url, 256);
    Format(url, 256, "%s/?action=search&engine=%s&limit=%d&song=%s", url, g_EngineName[g_kEngine[client]], g_cvarLIMITS.IntValue, sArgs);
    //i dont want to urlencode. xD
    ReplaceString(url, 256, " ", "+", false);

#if defined DEBUG
    UTIL_DebugLog("OnClientSayCommand -> %N -> %s -> %s", client, sArgs, url);
#endif

    char path[128];
    BuildPath(Path_SM, path, 128, "data/music/search_%s_%d.kv", g_EngineName[g_kEngine[client]], GetClientUserId(client));

    // processing search
    if(g_bSystem2)
    {
        System2HTTPRequest hRequest = new System2HTTPRequest(API_SearchMusic_System2, url);
        hRequest.SetOutputFile(path);
        hRequest.Timeout = 30;
        hRequest.Any = GetClientUserId(client);
        hRequest.GET();
        delete hRequest;
    }
    else
    {
        Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        SteamWorks_SetHTTPRequestContextValue(hRequest, GetClientUserId(client));
        SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, 30);
        SteamWorks_SetHTTPCallbacks(hRequest, API_SearchMusic_SteamWorks);
        SteamWorks_SendHTTPRequest(hRequest);
        delete hRequest;
    }
    
    g_bLocked[client] = true;

    return Plugin_Stop;
}