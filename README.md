# Advanced Music Player  
  
  
An advanced music player in source engine game.  
  
  
[![YouTube Video](https://static.kxnrl.com/images/web/github/amp_readme.png)](https://youtu.be/3A6XLhThBOI)  
  
  
|Build Status|Download|
|---|---
|[![Build Status](https://img.shields.io/travis/Kxnrl/AdvMusicPlayer/master.svg?style=flat-square)](https://travis-ci.org/Kxnrl/AdvMusicPlayer?branch=master) |[![Download](https://static.kxnrl.com/images/web/buttons/download.png)](https://build.kxnrl.com/AdvMusicPlayer)  
  
  
## Requirements  
#### Extensions (Select one, if both were installed, priority use System2)  
- [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556 "AlliedModders") - Required to download anything.  
- [System2](https://forums.alliedmods.net/showthread.php?t=146019 "AlliedModders") - Required to download anything. (version >= 3.0)  
  
  
## Recommend Plugins  
- [MapMusic](https://github.com/Kxnrl/MapMusic-API/ "GitHub") - To control map music when player is playing. 
- [Store](https://github.com/Kxnrl/Store/ "GitHub") - Cost credits to broadcast music.  
  
  
## Installation  
- Download and install requirements.  
- [Download](https://build.kxnrl.com/AdvMusicPlayer) latest build.  
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
