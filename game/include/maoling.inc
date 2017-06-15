#include <sdktools>

stock bool IsValidClient(int client, bool fake = true)
{
	if(client > MaxClients || client < 1)
		return false;

	if(!IsClientInGame(client))
		return false;
	
	if(fake && IsFakeClient(client))
		return false;

	return true;
}

stock void ReplaceColorsCode(char[] buffer, int maxLen)
{
	ReplaceString(buffer, maxLen, "{normal}", "\x01", false);
	ReplaceString(buffer, maxLen, "{default}", "\x01", false);
	ReplaceString(buffer, maxLen, "{white}", "\x01", false);
	ReplaceString(buffer, maxLen, "{darkred}", "\x02", false);
	ReplaceString(buffer, maxLen, "{pink}", "\x03", false);
	ReplaceString(buffer, maxLen, "{green}", "\x04", false);
	ReplaceString(buffer, maxLen, "{lime}", "\x05", false);
	ReplaceString(buffer, maxLen, "{yellow}", "\x05", false);
	ReplaceString(buffer, maxLen, "{lightgreen}", "\x06", false);
	ReplaceString(buffer, maxLen, "{lightred}", "\x07", false);
	ReplaceString(buffer, maxLen, "{red}", "\x07", false);
	ReplaceString(buffer, maxLen, "{gray}", "\x08", false);
	ReplaceString(buffer, maxLen, "{grey}", "\x08", false);
	ReplaceString(buffer, maxLen, "{olive}", "\x09", false);
	ReplaceString(buffer, maxLen, "{orange}", "\x10", false);
	ReplaceString(buffer, maxLen, "{purple}", "\x0E", false);
	ReplaceString(buffer, maxLen, "{lightblue}", "\x0B", false);
	ReplaceString(buffer, maxLen, "{blue}", "\x0C", false);
}

stock void ClearTimer(Handle &timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, fmt, 3);
	
	if(GetEngineVersion() == Engine_CSGO)
		Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
	else
	{
		ReplaceString(m_szBuffer, 256, "\n \n", " - ");
		ReplaceString(m_szBuffer, 256, "\n", " - ");
	}
	
	SetMenuTitle(menu, m_szBuffer);
}

stock bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);

	if(GetEngineVersion() != Engine_CSGO)
		ReplaceString(m_szBuffer, 256, "\n", " - ");

	return AddMenuItem(menu, info, m_szBuffer, style);
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
	if(client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if(!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char szBuffer[256];

	SetGlobalTransTarget(client);
	VFormat(szBuffer, 256, szMessage, 3);
	ReplaceColorsCode(szBuffer, 256);
	PrintToChat(client, szBuffer);
}

stock void tPrintToChatAll(const char[] szMessage, any ...)
{
	char szBuffer[256];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);			
			VFormat(szBuffer, 256, szMessage, 2);
			ReplaceColorsCode(szBuffer, 256);
			PrintToChat(i, "%s", szBuffer);
		}
	}
}