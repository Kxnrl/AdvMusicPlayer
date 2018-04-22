/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          system2.sp                                     */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2017  Kyle                                      */
/*  2017/12/30 22:06:14                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License    .            */
/*                                                                */
/******************************************************************/

// system2 v2.6 or later

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
            // php echo "success!" mean preloading success. "file_exists!" mean we were precached.
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
                LogError("System2 -> API_CachedSong -> [%s]", output);
        }
        case CMD_ERROR  : LogError("System2 -> API_CachedSong -> [%s]", output);
        default: LogError("System2 -> API_CachedSong -> [%s]", output[0] ? output : "Error Unknown");
    }
}

public void API_DownloadTranslations_System2(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int index)
{
    if(finished)
    {
        if(!StrEqual(error, ""))
            SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: %s", error);

        char path[128];
        BuildPath(Path_SM, path, 128, "translations/com.kxnrl.amp.translations.txt");

        if(!FileExists(path))
            SetFailState("System2 -> API_DownloadTranslations -> Download Translations Error: File does not exists!");

        if(FileSize(path) < 2048)
        {
            char content[2048];
            File file = OpenFile(path, "r+");
            ReadFileString(file, content, 2048);
            delete file;
            SetFailState("Download Translations Error: %s", content);
        }

        LoadTranslations("com.kxnrl.amp.translations");
    }
}