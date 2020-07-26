#if defined _audio_included
  #endinput
#endif
#define _audio_included

native bool AudioMixer_GetClientCanHearSelf(int client);

native void AudioMixer_SetClientCanHearSelf(int client, bool hearself);

methodmap AudioPlayer < Handle
{
    public native AudioPlayer();

    property float PlayedSecs {
        public native get();
    }

    property bool IsFinished {
        public native get();
    }

    property int ClientIndex {
        public native get();
    }

    public native void SetFrom(float ss);

    public native void AddInputArg(const char[] arg);

    public native void AddArg(const char[] arg);

    public native void PlayAsClient(int client, const char[] uri);
}


public Extension __ext_audio = 
{
    name = "Audio",
    file = "audio.ext",
#if defined AUTOLOAD_EXTENSIONS
    autoload = 1,
#else
    autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_audio_SetNTVOptional()
{
    MarkNativeAsOptional("AudioPlayer.AudioPlayer");
    MarkNativeAsOptional("AudioPlayer.PlayedSecs.get");
    MarkNativeAsOptional("AudioPlayer.IsFinished.get");
    MarkNativeAsOptional("AudioPlayer.SetFrom");
    MarkNativeAsOptional("AudioPlayer.PlayAsClient");
}
#endif
