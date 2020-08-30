# Advanced Music Player  
  
  
An advanced music player in source engine game.  
  
  
[![YouTube Video](https://static.kxnrl.com/images/web/github/amp_readme.png)](https://youtu.be/3A6XLhThBOI)  
  
  
|Build Status|Download|
|---|---
|[![Build Status](https://img.shields.io/travis/Kxnrl/AdvMusicPlayer/csgo.svg?style=flat-square)](https://travis-ci.org/Kxnrl/AdvMusicPlayer?branch=csgo) |[![Download](https://static.kxnrl.com/images/web/buttons/download.png)](https://build.kxnrl.com/AdvMusicPlayer)  
  
  
## Requirements  
#### Extensions
- [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556 "AlliedModders") - Required to download anything.  
  
  
## Recommend Plugins  
- [MapMusic](https://github.com/Kxnrl/MapMusic-API/ "GitHub") - To control map music when player is playing. 
- [Store](https://github.com/Kxnrl/Store/ "GitHub") - Cost credits to broadcast music.  
  
  
## Installation  
- Download and install requirements.  
- [Download](https://build.kxnrl.com/AdvMusicPlayer) latest build.  
- Download ffmpeg precompiled ([windows](https://ffmpeg.zeranoe.com/builds/) | [linux](https://johnvansickle.com/ffmpeg/)) and upload `ffmpeg.exe` (for windows) or `ffmpeg` (for linux) to `addons/sourcemod/data/audio_ext`.
- Upload web patch to your web host. (If you want to use our music server, ship this. Recommend using our music server)  
- Upload smx plugin to your {game dir}/addons/sourcemod/plugins .  
- Start your server.  
  
  
## Commands  
- **sm_music** - Open main menu. [alias: ***sm_dj*** / ***sm_media***]  
- **sm_adminmusicstop** - [Ban flag] Stop broadcasting.  
- **sm_musicban** - [Ban flag] Bans the selected player from broadcasting. [Usage: sm_musicban <steamid|userid>] 
  
  
## Console Variables  
- **amp_api_engine** - Url for music engine API.  
- **amp_lrc_delay** - How many second(s) delay to display lyric on lyric loaded, use to adjust lyrics.  
- **amp_mnt_search** - How many songs will display in once search.  
- **amp_cost_factor** - How much for broadcasting song (per second).  
