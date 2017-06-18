/**
 * =============================================================================
 * WebLync for SourceMod (C)2017 Matthew J Dunn.   All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if defined _webblync_included
  #endinput
#endif
#define _webblync_included

typedef WebLyncGetUrlParam = function bool (int client, const char[] paramname, char[] buffer, int maxlength);

native void WebLync_OpenUrl(int client, const char[] url);
native void WebLync_RegisterUrlParam(const char[] paramname, WebLyncGetUrlParam callback);
native void WebLync_UnregisterUrlParam(const char[] paramname);

public __pl_weblync_SetNTVOptional()
{
	MarkNativeAsOptional("WebLync_OpenUrl");
	MarkNativeAsOptional("WebLync_RegisterUrlParam");
	MarkNativeAsOptional("WebLync_UnregisterUrlParam");
}

public SharedPlugin __pl_weblync = 
{
	name = "weblync",
	file = "weblync.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};