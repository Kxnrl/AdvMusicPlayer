/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          system2.sp                                     */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle   https://ump45.moe                  */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



public void API_SearchMusic_System2(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int userid)
{
    if(finished)
    {
        if(!StrEqual(error, ""))
        {
            LogError("System2 -> API_SearchMusic -> Download result Error: %s", error);
            return;
        }

        UTIL_ProcessResult(userid);
    }
}

public void API_GetLyric_System2(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int index)
{
    if(finished)
    {
        if(!StrEqual(error, ""))
        {
            LogError("System2 -> API_GetLyric -> Download lyric Error: %s", error);
            return;
        }

        UTIL_ProcessLyric(index);
    }
}

public void API_CachedSong_System2(const char[] output, const int size, CMDReturn status, int values)
{
    g_fNextPlay = 0.0;

    switch(status)
    {
        case CMD_SUCCESS:
        {
            if(strcmp(output, "success!", false) == 0 || strcmp(output, "file_exists!", false) == 0)
            {
                int client = values & 0x7f;
                int index  = values >> 7;
                if(index == 0)
                    Player_BroadcastMusic(client, true);
                else
                    Player_ListenMusic(client, true);
            }
            else
                LogError("API_CachedSong -> [%s]", output);
        }
        case CMD_ERROR  : LogError("API_CachedSong -> [%s]", output);
    }
}