#if defined _MapMuisc_INCLUDED
    #endinput
#endif

#define _MapMuisc_INCLUDED

native int MapMusic_GetVolume(int client);
native void MapMusic_SetVolume(int client, int volume); // 0 ~ 100;
native bool MapMusic_GetStatus(int client); // true = Block map music;
native void MapMusic_SetStatus(int client, bool blockMapMusic); 
native void MapMusic_BlockAll(bool blockAllMusic);

forward void MapMusic_OnVolumeChanged(int client, float volume);
forward void MapMusic_OnStatusChanged(int client, bool blockMusic);

public SharedPlugin __pl_mapmusic = 
{
	name = "MapMusic",
	file = "mapmusic.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};