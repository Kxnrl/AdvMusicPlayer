#if defined _Store_INCLUDED
    #endinput
#endif

#define _Store_INCLUDED

public SharedPlugin __pl_store = 
{
	name = "store",
	file = "store.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

native int Store_GetClientCredits(int client);
native int Store_SetClientCredits(int client, int credits, const char[] log = "未知");
