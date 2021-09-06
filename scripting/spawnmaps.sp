/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "Spawn Maps"
#define PLUGIN_DESCRIPTION "An easy method of spawning points at random coordinates inside the map."
#define PLUGIN_VERSION "1.0.0"

#define BASE_PATH "data/spawnmaps"

/*****************************/
//Includes
#include <sourcemod>
#include <sdktools>

/*****************************/
//ConVars

/*****************************/
//Globals

ArrayList g_SpawnMaps;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("spawnmaps");
	
	CreateNative("SpawnMaps_Get", Native_Get);
	CreateNative("SpawnMaps_GetRandom", Native_GetRandom);
	CreateNative("SpawnMaps_GetTotalSpawns", Native_GetTotalSpawns);
	CreateNative("SpawnMaps_Add", Native_Add);
	
	return APLRes_Success;
}

public int Native_Get(Handle plugin, int numParams)
{
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (g_SpawnMaps.Length < 1)
		return ThrowNativeError(SP_ERROR_NATIVE, "No spawn maps available for the map: %s", sMap);
	
	int index = GetNativeCell(1);
	
	if (index < 0 || index > g_SpawnMaps.Length - 1)
		return ThrowNativeError(SP_ERROR_NATIVE, "Index must be between 0 to %i.", g_SpawnMaps.Length - 1);
	
	float origin[3];
	g_SpawnMaps.GetArray(index, origin, sizeof(origin));
	
	SetNativeArray(2, origin, sizeof(origin));
	return true;
}

public int Native_GetRandom(Handle plugin, int numParams)
{
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (g_SpawnMaps.Length < 1)
		return ThrowNativeError(SP_ERROR_NATIVE, "No spawn maps available for the map: %s", sMap);
	
	float origin[3];
	g_SpawnMaps.GetArray(GetRandomInt(0, g_SpawnMaps.Length - 1), origin, sizeof(origin));
	
	SetNativeArray(1, origin, sizeof(origin));
	return true;
}

public int Native_GetTotalSpawns(Handle plugin, int numParams)
{
	return g_SpawnMaps.Length;
}

public int Native_Add(Handle plugin, int numParams)
{
	float origin[3];
	GetNativeArray(1, origin, sizeof(origin));
	AddSpawnMap(origin);
}

public void OnPluginStart()
{
	g_SpawnMaps = new ArrayList(3);
	HookEvent("player_death", Event_OnPlayerDeath);
}

public void OnMapStart()
{
	g_SpawnMaps.Clear();
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", BASE_PATH);
	
	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath))
			SetFailState("Failed to create directory at %s - Please manually create that path and reload this plugin.", BASE_PATH);
	}
	
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	GetMapDisplayName(sMap, sMap, sizeof(sMap));
	
	Format(sPath, sizeof(sPath), "%s/%s.ini", sPath, sMap);
	PrintToServer(sPath);
	File file = OpenFile(sPath, "r");
	
	if (file == null)
		return;
	
	char line[256];
	while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
	{
		TrimString(line);
		
		char sPart[3][32];
		int found = ExplodeString(line, " ", sPart, 3, 32, false);
		
		if (found == 3)
		{
			float origin[3];
			origin[0] = StringToFloat(sPart[0]);
			origin[1] = StringToFloat(sPart[1]);
			origin[2] = StringToFloat(sPart[2]);
			
			g_SpawnMaps.PushArray(origin, sizeof(origin));
		}
	}

	file.Close();
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_SpawnMaps.Length >= 100)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	float origin[3];
	GetEntGroundCoordinates(client, origin);
	
	AddSpawnMap(origin);
}

void AddSpawnMap(float origin[3])
{
	g_SpawnMaps.PushArray(origin, sizeof(origin));
	
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	GetMapDisplayName(sMap, sMap, sizeof(sMap));
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s.ini", BASE_PATH, sMap);
	
	File file = OpenFile(sPath, "a");
	file.WriteLine("%.2f %.2f %.2f", origin[0], origin[1], origin[2]);
	file.Close();
}

bool GetEntGroundCoordinates(int entity, float buffer[3], float distance = 0.0, float offset[3] = {0.0, 0.0, 0.0})
{
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecOrigin);

	float vecLook[3] = {90.0, 0.0, 0.0};
	Handle trace = TR_TraceRayFilterEx(vecOrigin, vecLook, MASK_SOLID_BRUSHONLY, RayType_Infinite, ___TraceEntityFilter_NoPlayers, entity);

	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(buffer, trace);
		delete trace;
		
		buffer[0] += offset[0]; buffer[1] += offset[1]; buffer[2] += offset[2];
		return (distance > 0.0 && vecOrigin[2] - buffer[2] > distance);
	}

	delete trace;
	return false;
}

public bool ___TraceEntityFilter_NoPlayers(int entity, int contentsMask, any data)
{
	return entity != data && entity > MaxClients;
}