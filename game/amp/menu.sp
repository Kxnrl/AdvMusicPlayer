/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          menu.sp                                        */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
/*                                                                */
/******************************************************************/



void DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHanlder_Main);
    
    if(g_bPlayed[client] || g_bListen[client])
        SetMenuTitle(menu, "%T", "player info", client, g_Sound[client][szName], g_Sound[client][szSinger], g_Sound[client][szAlbum]); 
    else
        SetMenuTitle(menu, "%T", "player title", client);

    AddMenuItemEx(menu, g_bPlayed[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "search",  "%T", "search", client);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "toggle", "%T", "receive", client, g_bDiable[client] ? "OFF" : "ON");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lyrics", "%T", "lyrics",  client, g_bLyrics[client] ? "ON" : "OFF");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "volume", "%T", "volume",  client, g_iVolume[client]);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "stop",   "%T", "stop playing", client);
    AddMenuItemEx(menu, g_bMapMusic ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "mapbgm", "地图音量: %d", g_iBGMVol[client]);

    DisplayMenu(menu, client, 30);
}

public int MenuHanlder_Main(Handle menu, MenuAction action, int client, int slot)
{
    if(action == MenuAction_Select)
    {
        bool reply = true;
        
#if defined DEBUG
        UTIL_DebugLog("MenuHanlder_Main -> %N -> %d", client, slot);
#endif

        switch(slot)
        {
            case 0:
            {
                reply = false;
                g_bHandle[client] = true;
                Chat(client, "%t", "search help");
            }
            case 1:
            {
                g_bDiable[client] = !g_bDiable[client];
                SetClientCookie(client, g_cDisable, g_bDiable[client] ? "1" : "0");
                Chat(client, "%t", "receive chat", g_bDiable[client] ? "\x07OFF" : "\x04ON");
                if(g_bDiable[client] && g_bPlayed[client] && !g_bListen[client])
                {
                    Player_Reset(client, true);
                    Player_LyricHud(client, "0.5", "");
                }
            }
            case 2:
            {
                g_bLyrics[client] = !g_bLyrics[client];
                SetClientCookie(client, g_cLyrics, g_bLyrics[client] ? "0" : "1");
                Chat(client, "%t", "receive chat", g_bLyrics[client] ? "\x04ON" : "\x07OFF");
            }
            case 3:
            {
                if(g_iVolume[client] >= 10)
                    g_iVolume[client] -= 10;
                else
                    g_iVolume[client] = 100;
                char buf[4];
                IntToString(g_iVolume[client], buf, 4);
                SetClientCookie(client, g_cVolume, buf);
                Chat(client, "%t", "volume chat");
            }
            case 4:
            {
                Player_Reset(client, true);
                Chat(client, "%t", "stop chat");
            }
            case 5:
            {
                if(g_iBGMVol[client] >= 10)
                    g_iBGMVol[client] -= 10;
                else
                    g_iBGMVol[client] = 100;

                char buf[4];
                IntToString(g_iBGMVol[client], buf, 4);
                SetClientCookie(client, g_cBGMVol, buf);
                MapMusic_SetVolume(client, g_iBGMVol[client]);
            }
        }

        if(reply) DisplayMainMenu(client);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public int MenuHandler_DisplayList(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select) 
    {
#if defined DEBUG
        UTIL_DebugLog("MenuHandler_DisplayList -> %N -> %d", client, itemNum);
#endif

        g_iSelect[client] = itemNum - (itemNum/6);
        
        int length, sid;
        char name[128], arlist[64], album[64];
        UTIL_ProcessSongInfo(client, name, arlist, album, length, sid);

        DisplayConfirmMenu(client, cost, name, arlist, album, length);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplayConfirmMenu(int client, int cost, const char[] name, const char[] arlist, const char[] album, int time)
{
    Handle menu = CreateMenu(MenuHandler_Confirm);
    SetMenuTitle(menu, "%T", "confirm broadcast", client);
    
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song title",  client, name);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song artist", client, arlist);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song album",  client, album);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song length", client, time/60, time%60);

    if(g_bStoreLib)
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "%T", "cost money", client, cost);
    else
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "%T", "cost free", client);

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "%T", "cost self", client);

    DisplayMenu(menu, client, 15);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int slot)
{
    if(action ==  MenuAction_Select)
    { 
#if defined DEBUG
        UTIL_DebugLog("MenuHandler_Confirm -> %N -> %d", client, slot);
#endif

        if(slot == 4)
            Player_BroadcastMusic(client, false);
        else if(slot == 5)
            Player_ListenMusic(client, false);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}