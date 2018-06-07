# AdvMusicPlayer  
  
 
An advanced music player in csgo.  
[YouTube Video](https://www.youtube.com/watch?v=64FPl4TIMbc "YouTube")  
  
  
|Build Status|Download|
|---|---
|[![Build Status](https://img.shields.io/travis/Kxnrl/AdvMusicPlayer/master.svg?style=flat-square)](https://travis-ci.org/Kxnrl/AdvMusicPlayer?branch=master) |[![Download](https://static.kxnrl.com/images/web/buttons/download.png)](https://build.kxnrl.com/AdvMusicPlayer/)  
  
  
## Requirements  
#### Extensions (Select one, if both were installed, priority use System2)  
- [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556 "AlliedModders") - Required to download anythings.  
- [System2](https://forums.alliedmods.net/showthread.php?t=146019 "AlliedModders") - Required to download anythings or open page (>= 3.0).  
  
  
## Recommend Plugins  
- [MapMusic](https://github.com/Kxnrl/MapMusic-API/ "GitHub") - To control map music when player is playing. 
- [Store](https://github.com/Kxnrl/Store/ "GitHub") - Cost credits to broadcast music.  
  
  
## Installation  
- Download and install requirements.  
- [Download](https://static.kxnrl.com/images/web/buttons/download.png) latest build.  
- Upload web patch to your web host. (if u want to use our musicserver, ignore this step)  
- Upload smx plugin to your {game dir}/addons/sourcemod/plugins .  
- Make sure url in your {game dir}/cfg/com.kxnrl.AdvMusicPlayer.cfg .
- Start your server.  
  
  
## Commands  
- **sm_music** - Open main menu. [alias: ***sm_dj*** / ***sm_media***]  
- **sm_adminmusicstop** - [Admin Command - Ban flag] Stop broadcasting.  
- **sm_musicban** - [Admin Command - Ban flag] Bans the selected player from broadcasting. [Usage: sm_musicban <player steamid|userid>] 
  
  
## Console Variables  
- **amp_url_search** - url for searching music.  
- **amp_url_lyrics** - url for downloading lyric.  
- **amp_url_player** - url of motd player.  
- **amp_url_cached** - url for caching music.  
- **amp_url_cached_enable** - enable music cached in your web server.  
- **amp_cost_factor** - how much for broadcasting song (per second), allow float.  
