#if defined _spawnmaps_included
  #endinput
#endif
#define _spawnmaps_included

native void SpawnMaps_Get(int index, float origin[3]);
native void SpawnMaps_GetRandom(float origin[3]);
native int SpawnMaps_GetTotalSpawns();
native void SpawnMaps_Add(float origin[3]);

#if !defined REQUIRE_PLUGIN
public void __pl_spawnmaps_SetNTVOptional()
{
	MarkNativeAsOptional("SpawnMaps_Get");
	MarkNativeAsOptional("SpawnMaps_GetRandom");
	MarkNativeAsOptional("SpawnMaps_GetTotalSpawns");
	MarkNativeAsOptional("SpawnMaps_Add");
}
#endif

public SharedPlugin __pl_spawnmaps =
{
	name = "spawnmaps",
	file = "spawnmaps.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};