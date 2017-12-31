/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          menu.sp                                        */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle   https://ump45.moe                  */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



void DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHanlder_Main);
    
    if(g_bPlayed[client] || g_bListen[client])
        SetMenuTitle(menu, "正在播放▼\n \n歌名: %s\n歌手: %s\n专辑: %s\n ", g_Sound[client][szName], g_Sound[client][szSinger], g_Sound[client][szAlbum]); 
    else
        SetMenuTitle(menu, "[多媒体系统]  主菜单\n ");

    AddMenuItemEx(menu, g_bPlayed[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, "search",  "搜索音乐");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "toggle", "点歌接收: %s", g_bDiable[client] ? "关" : "开");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lyrics", "歌词显示: %s", g_bLyrics[client] ? "开" : "关");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "volume", "点歌音量: %d", g_iVolume[client]);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "stop",   "停止播放");
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
                PrintToChat(client, "%s  按Y输入 歌名( - 歌手) [小括号内选填]", PREFIX);
            }
            case 1:
            {
                g_bDiable[client] = !g_bDiable[client];
                SetClientCookie(client, g_cDisable, g_bDiable[client] ? "1" : "0");
                PrintToChat(client, "%s  \x10点歌接收已%s", PREFIX, g_bDiable[client] ? "\x07关闭" : "\x04开启");
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
                PrintToChat(client, "%s  \x10歌词显示已%s", PREFIX, g_bLyrics[client] ? "\x04开启" : "\x07关闭");
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
                PrintToChat(client, "%s  \x10音量设置将在下次播放时生效", PREFIX);
            }
            case 4:
            {
                Player_Reset(client, true);
                PrintToChat(client, "%s  \x04音乐已停止播放", PREFIX);
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

        g_iSelect[client] = itemNum;
        
        int length, sid;
        char name[128], arlist[64], album[64];
        UTIL_ProcessSongInfo(client, name, arlist, album, length, sid);

        int cost = RoundFloat(length*g_fFactorCredits);
        if(g_bStoreLib && Store_GetClientCredits(client) < cost)
        {
            PrintToChat(client, "%s  \x07你的信用点不足\x04%d\x07!", PREFIX, cost);
            return;
        }

        DisplayConfirmMenu(client, cost, name, arlist, album, length);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplayConfirmMenu(int client, int cost, const char[] name, const char[] arlist, const char[] album, int time)
{
    Handle menu = CreateMenu(MenuHandler_Confirm);
    SetMenuTitle(menu, "您确定要点播以下歌曲吗\n ");
    
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "歌名: %s", name);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "歌手: %s", arlist);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "专辑: %s", album);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, " ", "时长: %d分%d秒\n ", time/60, time%60);

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "所有人[花费: %d信用点]", cost);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "自己听[免费]");

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