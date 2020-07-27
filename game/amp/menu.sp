/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          menu.sp                                        */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2018/07/04 05:37:22                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



void DisplayMainMenu(int client)
{
    Menu menu = new Menu(MenuHanlder_Main);

    if (IsPlaying())
        menu.SetTitle("%T", "player info", client, g_Player.m_Title, g_Player.m_Artist, g_Player.m_Album, g_EngineName[g_Player.m_Engine], client);
    else
        menu.SetTitle("%T", "player title", client);

#if defined DEBUG
    UTIL_DebugLog("DisplayMainMenu -> %N -> %b | %b -> %.1f", client, g_Player.m_Player != null, g_Player.m_Player != null && g_Player.m_Player.IsFinished, g_Player.m_Player != null ? g_Player.m_Player.PlayedSecs : 0.0);
#endif

    AddMenuItemEx(menu, IsPlaying()       ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "search",  "%T", "search", client);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "toggle", "%T", "receive", client, g_bDiable[client] ? "OFF" : "ON");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lyrics", "%T", "lyrics",  client, g_bLyrics[client] ? "ON" : "OFF");
    AddMenuItemEx(menu, AllowStop(client) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "stop",   "%T", "stop playing", client);
    AddMenuItemEx(menu, g_bMapMusic ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "mapbgm", "%T: %d", g_bMapMusic ? "map bgm a" : "map bgm ua", client, g_bMapMusic ? MapMusic_GetVolume(client) : 100);

    menu.Display(client, 30);
}

public int MenuHanlder_Main(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_Select)
    {
        bool reply = false;
        
#if defined DEBUG
        UTIL_DebugLog("MenuHanlder_Main -> %N -> %d", client, slot);
#endif

        switch(slot)
        {
            case 0: DisplayEngineMenu(client);
            case 1:
            {
                reply = true;
                g_bDiable[client] = !g_bDiable[client];
                Cookie_SetValue(client, Opts_Enable, g_bDiable[client]);
                Chat(client, "%T", "receive chat", client, g_bDiable[client] ? "\x07OFF" : "\x04ON");
            }
            case 2:
            {
                reply = true;
                g_bLyrics[client] = !g_bLyrics[client];
                Cookie_SetValue(client, Opts_Lyrics, g_bLyrics[client]);
                Chat(client, "%T", "receive chat", client, g_bLyrics[client] ? "\x04ON" : "\x07OFF");
            }
            case 3:
            {
                // in playing?
                if (IsPlaying())
                    SetListenOverride(client, g_Player.m_Player.ClientIndex, Listen_No);
                Chat(client, "%T", "stop chat", client);
                reply = true;
            }
            case 4: FakeClientCommandEx(client, "sm_mapmusic");
        }

        if (reply) DisplayMainMenu(client);
    }
    else if (action == MenuAction_End)
        delete menu;
}

void DisplayEngineMenu(int client)
{
    if (g_bLocked[client])
    {
        Chat(client, "%T", "locked search", client);
        return;
    }
    
    Menu menu = new Menu(MenuHanlder_Engine);

    menu.SetTitle("%T", "Engine title", client);

    for(int i = 0; i < view_as<int>(kEngine); ++i)
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, g_EngineName[view_as<kEngine>(i)], "%T", g_EngineName[view_as<kEngine>(i)],  client);

    menu.ExitButton = false;
    menu.ExitBackButton = true;
    menu.Display(client, 15);
}

public int MenuHanlder_Engine(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
        DisplayMainMenu(client);
    else if (action == MenuAction_Select)
    {
        g_bHandle[client] = true;
        g_kEngine[client] = view_as<kEngine>(itemNum);
        Chat(client, "%T", "search help", client);
    }
}

public int MenuHandler_DisplayList(Menu menu, MenuAction action, int client, int itemNum)
{
    if (action == MenuAction_Select) 
    {
#if defined DEBUG
        UTIL_DebugLog("MenuHandler_DisplayList -> %N -> %d", client, itemNum);
#endif

        g_iSelect[client] = itemNum - (itemNum/6);

        float length;
        kEngine engine;
        char name[64], artist[64], album[64], sid[16];
        UTIL_ProcessSongInfo(client, name, artist, album, length, sid, engine);

        int cost = RoundFloat(length*g_Cvars.credit.FloatValue);
        DisplayConfirmMenu(client, cost, name, artist, album, RoundFloat(length), engine);
    }
    else if (action == MenuAction_End)
        delete menu;
}

void DisplayConfirmMenu(int client, int cost, const char[] name, const char[] arlist, const char[] album, int time, kEngine engine)
{
    Menu menu = new Menu(MenuHandler_Confirm);
    menu.SetTitle("%T (%T: %T)\n ", "confirm broadcast", client, "engine", client, g_EngineName[engine], client);

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song title",  client, name);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song artist", client, arlist);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song album",  client, album);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "%T", "song length", client, time/60, time%60);

    if (g_bStoreLib)
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "%T", "cost money", client, cost);
    else
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "%T", "cost free", client);

    menu.Display(client, 15);
}

public int MenuHandler_Confirm(Menu menu, MenuAction action, int client, int slot)
{
    if (action ==  MenuAction_Select)
    { 
#if defined DEBUG
        UTIL_DebugLog("MenuHandler_Confirm -> %N -> %d", client, slot);
#endif
        if (slot == 4)
            Player_BroadcastMusic(client, false);
    }
    else if (action == MenuAction_End)
        delete menu;
}