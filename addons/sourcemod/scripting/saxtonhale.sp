#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf_econ_data>
#include <dhooks>

#undef REQUIRE_EXTENSIONS
#tryinclude <tf2items>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#include "include/saxtonhale.inc"

#define UPDATE_URL                ""

#define PLUGIN_VERSION          "2.1.1"
#define PLUGIN_VERSION_REVISION "manual"

#if !defined SP_MAX_EXEC_PARAMS
  #define SP_MAX_EXEC_PARAMS          32 // Max possible params in SourcePawn
#endif

#define MAX_BUTTONS                   26
#define MAX_TYPE_CHAR                 32 // Max char size of methodmaps name

#define MAX_CONFIG_ARRAY              16 // Config: Max array size for multiple values of a single parameter
#define MAXLEN_CONFIG_VALUE           256 // Config: Max string buffer size for individual values
#define MAXLEN_CONFIG_VALUEARRAY      1024 // Config: Max string buffer size for groups of values

#define MAX_ATTRIBUTES_SENT           20

#define ATTRIB_MELEE_RANGE_MULTIPLIER 264
#define ATTRIB_BIDERECTIONAL          276
#define ATTRIB_JUMP_HEIGHT            326
#define ATTRIB_LESSHEALING            734

#define ITEM_ROCK_PAPER_SCISSORS		  1110

#define SOUND_ALERT       "ui/system_message_alert.wav"
#define SOUND_METERFULL   "player/recharged.wav"
#define SOUND_BACKSTAB    "player/spy_shield_break.wav"
#define SOUND_DOUBLEDONK  "player/doubledonk.wav"
#define SOUND_JAR_EXPLODE "weapons/jar_explode.wav"
#define SOUND_NULL        "vo/null.mp3"

#define PARTICLE_GHOST    "ghost_appearation"

// HIDEHUD_DEFINES
#define NONE 
#define	HIDEHUD_WEAPONSELECTION   (1<<0)  // Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT        (1<<1)
#define	HIDEHUD_ALL               (1<<2)
#define HIDEHUD_HEALTH            (1<<3)  // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD        (1<<4)  // Hide when local player's dead
#define HIDEHUD_NEEDSUIT          (1<<5)  // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS        (1<<6)  // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT              (1<<7)  // Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR         (1<<8)  // Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	(1<<9)  // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE         (1<<10)
#define HIDEHUD_BONUS_PROGRESS    (1<<11) // Hide bonus progress display (for bonus map challenges)
// TF2 Specific
#define HIDEHUD_BUILDING_STATUS   (1<<12) // Hide Engineer building status
#define HIDEHUD_CLOAK_AND_FEIGN   (1<<13)	// Hide item effect meter (cloak, etc)
#define HIDEHUD_PIPES_AND_CHARGE  (1<<14)	// Hide demo hud
#define HIDEHUD_METAL             (1<<15) // Metal/account hud
#define HIDEHUD_TARGET_ID         (1<<16) // Target ID
#define HIDEHUD_MATCH_STATUS      (1<<17) // Hide match status
#define HIDEHUD_BITCOUNT           18

const TFTeam TFTeam_Boss = TFTeam_Blue;
const TFTeam TFTeam_Attack = TFTeam_Red;

const TFObjectType TFObject_Invalid = view_as<TFObjectType>(-1);
const TFObjectMode TFObjectMode_Invalid = view_as<TFObjectMode>(-1);

enum ClientFlags
{
  ClientFlags_Admin = (1 << 0),
  ClientFlags_Punishment = (1 << 1),
};

// TODO:
// Verses: one boss vs everyone.
// Boss Vs Boss: split teams into 2, everyone is boss.
// Ultra: One Ultra boss vs bosses.
enum GameTypes {
  VERSES,
  BOSSVSBOSS,
  ULTRA,
};

enum
{
  WeaponSlot_Primary = 0,
  WeaponSlot_Secondary,
  WeaponSlot_Melee,
  WeaponSlot_PDABuild,
  WeaponSlot_PDADisguise = 3,
  WeaponSlot_PDADestroy,
  WeaponSlot_InvisWatch = 4,
  WeaponSlot_BuilderEngie,
  WeaponSlot_Unknown1,
  WeaponSlot_Head,
  WeaponSlot_Misc1,
  WeaponSlot_Action,
  WeaponSlot_Misc2
};

enum
{
  LifeState_Alive = 0,
  LifeState_Dead = 2
};

enum FlamethrowerState
{
  FlamethrowerState_Idle = 0,
  FlamethrowerState_StartFiring,
  FlamethrowerState_Firing,
  FlamethrowerState_Airblast,
};

enum
{
  COLLISION_GROUP_NONE  = 0,
  COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
  COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
  COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
  COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
  COLLISION_GROUP_PLAYER,
  COLLISION_GROUP_BREAKABLE_GLASS,
  COLLISION_GROUP_VEHICLE,
  COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
                    // TF2, this filters out other players and CBaseObjects
  COLLISION_GROUP_NPC,			// Generic NPC group
  COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
  COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
  COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
  COLLISION_GROUP_PROJECTILE,		// Projectiles!
  COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
  COLLISION_GROUP_PASSABLE_DOOR,	// Doors that the player shouldn't collide with
  COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
  COLLISION_GROUP_PUSHAWAY,		// Nonsolid on client and server, pushaway in player code

  COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
  COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

  LAST_SHARED_COLLISION_GROUP
};

// entity effects
enum
{
  EF_BONEMERGE			= (1<<0),	// Performs bone merge on client side
  EF_BRIGHTLIGHT			= (1<<1),	// DLIGHT centered at entity origin
  EF_DIMLIGHT				= (1<<2),	// player flashlight
  EF_NOINTERP				= (1<<3),	// don't interpolate the next frame
  EF_NOSHADOW				= (1<<4),	// Don't cast no shadow
  EF_NODRAW				= (1<<5),	// don't draw entity
  EF_NORECEIVESHADOW		= (1<<6),	// Don't receive no shadow
  EF_BONEMERGE_FASTCULL	= (1<<7),	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
                    // parent and uses the parent's bbox + the max extents of the aiment.
                    // Otherwise, it sets up the parent's bones every frame to figure out where to place
                    // the aiment, which is inefficient because it'll setup the parent's bones even if
                    // the parent is not in the PVS.
  EF_ITEM_BLINK			= (1<<8),	// blink an item so that the user notices it.
  EF_PARENT_ANIMATES		= (1<<9),	// always assume that the parent entity is animating
};

// Beam types, encoded as a byte
enum 
{
  BEAM_POINTS = 0,
  BEAM_ENTPOINT,
  BEAM_ENTS,
  BEAM_HOSE,
  BEAM_SPLINE,
  BEAM_LASER,
  NUM_BEAM_TYPES,
};

// Settings for m_takedamage - from shareddefs.h
enum
{
  DAMAGE_NO = 0,
  DAMAGE_EVENTS_ONLY,		// Call damage functions, but don't modify health
  DAMAGE_YES,
  DAMAGE_AIM,
};

// TF ammo types - from tf_shareddefs.h
enum
{
  TF_AMMO_DUMMY = 0,
  TF_AMMO_PRIMARY,
  TF_AMMO_SECONDARY,
  TF_AMMO_METAL,
  TF_AMMO_GRENADES1,
  TF_AMMO_GRENADES2,
  TF_AMMO_GRENADES3,

  TF_AMMO_COUNT,
};

enum
{
  CHANNEL_INTRO = 0,
  CHANNEL_HELP,
  CHANNEL_RAGE,
  CHANNEL_UNUSED1,
  CHANNEL_UNUSED2,
  CHANNEL_UNUSED3,
  CHANNEL_MAX = 6,
};

enum
{
  OBS_MODE_NONE = 0,	// not in spectator mode
  OBS_MODE_DEATHCAM,	// special mode for death cam animation
  OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
  OBS_MODE_FIXED,		// view from a fixed camera position
  OBS_MODE_IN_EYE,	// follow a player in first person view
  OBS_MODE_CHASE,		// follow a player in third person view
  OBS_MODE_POI,		// PASSTIME point of interest - game objective, big fight, anything interesting; added in the middle of the enum due to tons of hard-coded "<ROAMING" enum compares
  OBS_MODE_ROAMING,	// free roaming

  NUM_OBSERVER_MODES,
};



char g_strPreferencesName[][] = {
  "Boss Selection",
  "",
  "Multi Boss",
  "Music",
  "Revival"
};

// TF2 Class names, ordered from TFClassType
char g_strClassName[TFClassType][] = {
  "Unknown",
  "Scout",
  "Sniper",
  "Soldier",
  "Demoman",
  "Medic",
  "Heavy",
  "Pyro",
  "Spy",
  "Engineer",
};

// TF2 Slot names
char g_strSlotName[][] = {
  "Primary",
  "Secondary",
  "Melee",
  "PDA1",
  "PDA2",
  "Building"
};

// Color Tag
char g_strColorTag[][] = {
  "{positive}",
  "{green}",
  "{negative}",
  "{red}",
  "{neutral}",
  "{grey}"
};

// Default weapon index for each class and slot
int g_iDefaultWeaponIndex[][] = {
  {-1, -1, -1, -1, -1, -1},	//Unknown
  {13, 23, 0, -1, -1, -1},	//Scout
  {14, 16, 3, -1, -1, -1},	//Sniper
  {18, 10, 6, -1, -1, -1},	//Soldier
  {19, 20, 1, -1, -1, -1},	//Demoman
  {17, 29, 8, -1, -1, -1},	//Medic
  {15, 11, 5, -1, -1, -1},	//Heavy
  {21, 12, 2, -1, -1, -1},	//Pyro
  {24, 735, 4, 27, 30, -1},	//Spy
  {9, 22, 7, 25, 26, 28},		//Engineer
};

// List of class we use to display
TFClassType g_nClassDisplay[sizeof(g_strClassName)] = {
  TFClass_Unknown,
  TFClass_Scout,
  TFClass_Soldier,
  TFClass_Pyro,
  TFClass_DemoMan,
  TFClass_Heavy,
  TFClass_Engineer,
  TFClass_Medic,
  TFClass_Sniper,
  TFClass_Spy,
};

Cookie g_SetBossCookie;


// HALEDMG
enum {
	RED, GREEN, BLUE, ALPHA,
	MaxColors
}

enum struct DmgTrackerData {
	int RGBA[MaxColors];
	int DmgSetting;
}

DmgTrackerData g_dmg[MAXPLAYERS+1];
Handle         g_hDamageHUD;
Cookie         g_haledmg_cookie;




enum struct NextBoss
{
  int iId;                            // Id, must be at top of this struct
  int iClient;                        // Client to have those values, must be at 2nd top of this struct
  char sBossType[MAX_TYPE_CHAR];		  // Boss to play on next turn
  char sBossMultiType[MAX_TYPE_CHAR]; // Boss multi to play on next turn
  char sModifierType[MAX_TYPE_CHAR];	// Modifier to play on next turn
  bool bModifierSet;                  // Whenever if modifier has been set, forced no modifier also counts
  bool bForceNext;                    // This client will be boss next round
  bool bSpecialClassRound;            // All-Class on next turn
  TFClassType nSpecialClassType;      // If bSpecialClassRound, class to force, or TFClass_Unknown for random all-class
}

ArrayList g_aNextBoss;  // Arrays of NextBoss struct
int g_iNextBossId;      // Newest created id

bool g_bEnabled;
bool g_bForceLoad; // Addition: enable PL_ maps.
bool g_bRoundStarted;
bool g_bTF2Items;

int g_iSpritesLaserbeam;
int g_iSpritesGlow;

Handle g_hTimerBossMusic;
char g_sBossMusic[PLATFORM_MAX_PATH];
int g_iHealthBarHealth;
int g_iHealthBarMaxHealth;
int g_iTelefragBuilder;

//Player data
int g_iPlayerLastButtons[MAXPLAYERS];
int g_iPlayerDamage[MAXPLAYERS];
int g_iPlayerAssistDamage[MAXPLAYERS];
int g_iClientOwner[MAXPLAYERS];
bool g_bClientAreaOfEffect[MAXPLAYERS][MAXPLAYERS];
int g_iPlayerAirshotCount[MAXPLAYERS]; // Track airshots per player

int g_iClientFlags[MAXPLAYERS];

//Game state data
int g_iTotalRoundPlayed;
int g_iTotalAttackCount;

// ConVars
ConVar tf_arena_use_queue;
ConVar mp_teams_unbalance_limit;
ConVar tf_arena_first_blood;
ConVar tf_dropped_weapon_lifetime;
ConVar mp_forcecamera;
ConVar mp_friendlyfire;
ConVar tf_scout_hype_pep_max;
ConVar tf_damage_disablespread;
ConVar tf_feign_death_activate_damage_scale;
ConVar tf_feign_death_damage_scale;
ConVar tf_stealth_damage_reduction;
ConVar tf_feign_death_duration;
ConVar tf_feign_death_speed_duration;
ConVar tf_arena_preround_time;

#include "vsh/base_boss.sp"

#include "vsh/modifiers/modifiers_angry.sp"
#include "vsh/modifiers/modifiers_electric.sp"
#include "vsh/modifiers/modifiers_hot.sp"
#include "vsh/modifiers/modifiers_ice.sp"
#include "vsh/modifiers/modifiers_jumper.sp"
#include "vsh/modifiers/modifiers_magnet.sp"
#include "vsh/modifiers/modifiers_overload.sp"
#include "vsh/modifiers/modifiers_speed.sp"
#include "vsh/modifiers/modifiers_vampire.sp"

#include "vsh/tags/tags_params.sp"
#include "vsh/tags/tags_target.sp"
#include "vsh/tags/tags_filter.sp"
#include "vsh/tags/tags_block.sp"
#include "vsh/tags/tags_function.sp"
#include "vsh/tags/tags_call.sp"
#include "vsh/tags/tags_core.sp"
#include "vsh/tags/tags_damage.sp"
#include "vsh/tags/tags_name.sp"
#include "vsh/tags.sp"

#include "vsh/config.sp"

#include "vsh/menu/menu_admin.sp"
#include "vsh/menu/menu_boss.sp"
#include "vsh/menu/menu_weapon.sp"
#include "vsh/menu.sp"

#include "vsh/function/func_function.sp"
#include "vsh/function/func_stack.sp"
#include "vsh/function/func_call.sp"
#include "vsh/function/func_class.sp"
#include "vsh/function/func_hook.sp"
#include "vsh/function/func_native.sp"

#include "vsh/classlimit.sp"
#include "vsh/command.sp"
#include "vsh/console.sp"
#include "vsh/cookies.sp"
#include "vsh/dome.sp" // TODO: remove or change to different cap type
#include "vsh/event.sp"
#include "vsh/forward.sp"
#include "vsh/hud.sp"
#include "vsh/native.sp"
#include "vsh/nextboss.sp"
#include "vsh/preferences.sp"
#include "vsh/property.sp"
#include "vsh/queue.sp"
#include "vsh/sdk.sp"
#include "vsh/stocks.sp"

public Plugin myinfo =
{
  name              = "Versus Saxton Hale Rewrite",
  author            = "42, Kenzzer",
  description       = "Popular VSH Gamemode Rewritten from scrach",
  version           = PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION,
  url               = "https://github.com/redsunservers/VSH-Rewrite",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  Forward_AskLoad();
  FuncNative_AskLoad();
  Native_AskLoad();
  Property_AskLoad();
  
  RegPluginLibrary("saxtonhale");
  return APLRes_Success;
}

public void OnPluginStart()
{
  // OnLibraryAdded dont always call TF2Items on plugin start
  g_bTF2Items = LibraryExists("TF2Items");
  
  AddMultiTargetFilter("@hale", BossTargetFilter, "all bosses", false);
  AddMultiTargetFilter("@boss", BossTargetFilter, "all bosses", false);
  AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-bosses", false);
  AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-bosses", false);

  // Collect the convars
  tf_arena_use_queue                   = FindConVar("tf_arena_use_queue");
  mp_teams_unbalance_limit             = FindConVar("mp_teams_unbalance_limit");
  tf_arena_first_blood                 = FindConVar("tf_arena_first_blood");
  tf_dropped_weapon_lifetime           = FindConVar("tf_dropped_weapon_lifetime");
  mp_forcecamera                       = FindConVar("mp_forcecamera");
  mp_friendlyfire                      = FindConVar("mp_friendlyfire");
  tf_scout_hype_pep_max                = FindConVar("tf_scout_hype_pep_max");
  tf_damage_disablespread              = FindConVar("tf_damage_disablespread");
  tf_feign_death_activate_damage_scale = FindConVar("tf_feign_death_activate_damage_scale");
  tf_feign_death_damage_scale          = FindConVar("tf_feign_death_damage_scale");
  tf_stealth_damage_reduction          = FindConVar("tf_stealth_damage_reduction");
  tf_feign_death_duration              = FindConVar("tf_feign_death_duration");
  tf_feign_death_speed_duration        = FindConVar("tf_feign_death_speed_duration");
  tf_arena_preround_time               = FindConVar("tf_arena_preround_time");

  AddNormalSoundHook(NormalSoundHook);

  // Client Boss Preference Cookie
  g_SetBossCookie = RegClientCookie("SetBoss", "Stores player's chosen boss name", CookieAccess_Private);


  // Allow client 0 (server/console) use admin commands
  Client_AddFlag(0, ClientFlags_Admin);
  
  // Client 0 also used to call boss function and fetch data without needing active boss (precache, menus etc)
  // Modifiers should always be enabled, so modifiers function can be called
  SaxtonHaleBase boss = SaxtonHaleBase(0);
  boss.bModifiers = true;
  
  Config_Init();
  
  ClassLimit_Init();
  Command_Init();
  Console_Init();
  Cookies_Init();
  Dome_Init(); // TODO: rename or remove
  Event_Init();
  FuncClass_Init();
  FuncHook_Init();
  FuncNative_Init();
  FuncStack_Init();
  Menu_Init();
  NextBoss_Init();
  SDK_Init();
  TagsCall_Init();
  TagsCore_Init();
  TagsDamage_Init();
  TagsName_Init();

  // REWORK THIS LATERR
  DonatorSound_OnPluginStart();
  
  SaxtonHaleFunction func;
  
  // Boss functions
  SaxtonHaleFunction("IsBossHidden", ET_Single);
  
  func = SaxtonHaleFunction("GetBossName", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetBossInfo", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  // Multi Boss Functions
  SaxtonHaleFunction("IsBossMultiHidden", ET_Single);
  SaxtonHaleFunction("GetBossMultiList", ET_Ignore, Param_Cell);
  
  func = SaxtonHaleFunction("GetBossMultiType", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetBossMultiName", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetBossMultiInfo", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  // Modifiers functions
  SaxtonHaleFunction("IsModifiersHidden", ET_Single);
  
  func = SaxtonHaleFunction("GetModifiersName", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetModifiersInfo", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  // General functions
  SaxtonHaleFunction("OnThink", ET_Ignore);
  SaxtonHaleFunction("OnSpawn", ET_Ignore);
  SaxtonHaleFunction("OnRage", ET_Ignore);
  SaxtonHaleFunction("OnGiveNamedItem", ET_Single, Param_String, Param_Cell);
  SaxtonHaleFunction("OnEntityCreated", ET_Ignore, Param_Cell, Param_String);
  SaxtonHaleFunction("OnCommandKeyValues", ET_Hook, Param_String);
  SaxtonHaleFunction("OnAttackCritical", ET_Hook, Param_Cell, Param_CellByRef);
  SaxtonHaleFunction("OnVoiceCommand", ET_Hook, Param_String, Param_String);
  SaxtonHaleFunction("OnStartTouch", ET_Hook, Param_Cell);
  SaxtonHaleFunction("OnPickupTouch", ET_Ignore, Param_Cell, Param_CellByRef);
  SaxtonHaleFunction("OnWeaponSwitchPost", ET_Ignore, Param_Cell);
  SaxtonHaleFunction("OnConditionAdded", ET_Ignore, Param_Cell);
  SaxtonHaleFunction("OnConditionRemoved", ET_Ignore, Param_Cell);
  
  func = SaxtonHaleFunction("OnSoundPlayed", ET_Hook, Param_Array, Param_CellByRef, Param_String, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_String, Param_CellByRef);
  func.SetParam(1, Param_Array, VSHArrayType_Static, MAXPLAYERS);
  func.SetParam(3, Param_String, VSHArrayType_Static, PLATFORM_MAX_PATH);
  func.SetParam(9, Param_String, VSHArrayType_Static, PLATFORM_MAX_PATH);
  
  // Damage/Death functions
  SaxtonHaleFunction("OnPlayerKilled", ET_Ignore, Param_Cell, Param_Cell);
  SaxtonHaleFunction("OnDeath", ET_Ignore, Param_Cell);
  
  func = SaxtonHaleFunction("OnAttackBuilding", ET_Hook, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
  func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
  func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
  
  func = SaxtonHaleFunction("OnAttackDamage", ET_Hook, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
  func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
  func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
  
  func = SaxtonHaleFunction("OnTakeDamage", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
  func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
  func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
  
  func = SaxtonHaleFunction("OnAttackDamageAlive", ET_Hook, Param_Cell, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
  func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
  func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
  
  func = SaxtonHaleFunction("OnTakeDamageAlive", ET_Hook, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array, Param_Cell);
  func.SetParam(6, Param_Array, VSHArrayType_Static, 3);
  func.SetParam(7, Param_Array, VSHArrayType_Static, 3);
  
  // Button functions
  SaxtonHaleFunction("OnButton", ET_Ignore, Param_CellByRef);
  SaxtonHaleFunction("OnButtonPress", ET_Ignore, Param_Cell);
  SaxtonHaleFunction("OnButtonRelease", ET_Ignore, Param_Cell);
  
  // Building functions
  SaxtonHaleFunction("OnBuild", ET_Single, Param_Cell, Param_Cell);
  SaxtonHaleFunction("OnBuildObject", ET_Event, Param_Cell);
  SaxtonHaleFunction("OnDestroyObject", ET_Event, Param_Cell);
  SaxtonHaleFunction("OnObjectSapped", ET_Event, Param_Cell);
  
  // Retrieve array/strings
  func = SaxtonHaleFunction("GetModel", ET_Ignore, Param_String, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetSound", ET_Ignore, Param_String, Param_Cell, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetSoundKill", ET_Ignore, Param_String, Param_Cell, Param_Cell);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);

  func = SaxtonHaleFunction("GetSoundAbility", ET_Ignore, Param_String, Param_Cell, Param_String);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetRenderColor", ET_Ignore, Param_Array);
  func.SetParam(1, Param_Array, VSHArrayType_Static, 4);
  
  func = SaxtonHaleFunction("GetParticleEffect", ET_Ignore, Param_Cell, Param_String, Param_Cell);
  func.SetParam(2, Param_String, VSHArrayType_Dynamic, 3);
  
  func = SaxtonHaleFunction("GetMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  func = SaxtonHaleFunction("GetRageMusicInfo", ET_Ignore, Param_String, Param_Cell, Param_FloatByRef);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  
  SaxtonHaleFunction("UpdateHudInfo", ET_Ignore, Param_Cell, Param_Float);
  
  func = SaxtonHaleFunction("GetHudInfo", ET_Ignore, Param_String, Param_Cell, Param_Array);
  func.SetParam(1, Param_String, VSHArrayType_Dynamic, 2);
  func.SetParam(3, Param_Array, VSHArrayType_Static, 4);
  
  // Misc functions
  SaxtonHaleFunction("Precache", ET_Ignore);
  SaxtonHaleFunction("CalculateMaxHealth", ET_Single);
  SaxtonHaleFunction("CanHealTarget", ET_Hook, Param_Cell, Param_CellByRef);
  SaxtonHaleFunction("AddRage", ET_Ignore, Param_Cell);
  SaxtonHaleFunction("CreateWeapon", ET_Single, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String);
  
  // Register base constructor
  SaxtonHale_RegisterClass("SaxtonHaleBoss", VSHClassType_Core);
 
  // Register modifiers
  SaxtonHale_RegisterClass("ModifiersAngry", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersElectric", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersHot", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersIce", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersJumper", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersMagnet", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersOverload", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersSpeed", VSHClassType_Modifier);
  SaxtonHale_RegisterClass("ModifiersVampire", VSHClassType_Modifier);
  
  // Init our convars
  g_ConfigConvar.Create("vsh_force_load", "-1", "Force enable VSH on map start? (-1 for default, 0 for force disable, 1 for force enable)", _, true, -1.0, true, 1.0);
  g_ConfigConvar.Create("vsh_boss_ping_limit", "200", "Max ping/latency to allow player to play as boss (-1 for no limit)", _, true, -1.0);
  g_ConfigConvar.Create("vsh_telefrag_damage", "9001.0", "Damage amount to boss from telefrag", _, true, 0.0);
  g_ConfigConvar.Create("vsh_music_enable", "1", "Enable boss music?", _, true, 0.0, true, 1.0);
  g_ConfigConvar.Create("vsh_rps_enable", "1", "Allow everyone use Rock Paper Scissors Taunt?", _, true, 0.0, true, 1.0);

  g_haledmg_cookie = new Cookie("vsh_haledmg", "cookie to track boss damage settings", CookieAccess_Public);
  RegConsoleCmd("haledmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
  RegConsoleCmd("vshdmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
  RegConsoleCmd("ff2dmg",  Command_damagetracker, "haledmg - Enable/disable the damage tracker.");
  CreateTimer(180.0, Timer_Advertise);
  g_hDamageHUD = CreateHudSynchronizer();

  // Incase of lateload, call client join functions
  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    if (IsClientConnected(iClient))
      OnClientConnected(iClient);
    
    if (IsClientInGame(iClient))
    {
      OnClientPutInServer(iClient);
      OnClientPostAdminCheck(iClient);
    }
  }
}

public Action Command_damagetracker(int client, int args) {
	if (client==0) 
  {
		PrintToServer("[VSH 2] The damage tracker cannot be enabled by Console.");
		return Plugin_Handled;
	} 
  else if(args==0) 
  {
    // At start of function or block:
    char playersetting[4]; // Enough for "Off" or "On"
    if (g_dmg[client].DmgSetting == 0) {
      strcopy(playersetting, sizeof(playersetting), "Off");
    } else {
      strcopy(playersetting, sizeof(playersetting), "On");
    }
    PrintToChat(client, "[VSH] The damage tracker is %s.\n[VSH] Change it by saying \"!haledmg on [R] [G] [B] [A]\" or \"!haledmg off\"!", playersetting);
		return Plugin_Handled;
	}

	char arg1[64];
	int newval = 3;
	GetCmdArg(1, arg1, sizeof(arg1));
	if( StrEqual(arg1, "off", false) ) {
		g_dmg[client].DmgSetting = 0;
	}
	if( StrEqual(arg1, "on", false) ) {
		g_dmg[client].DmgSetting = 3;
	}
	if( StrEqual(arg1, "0", false) ) {
		g_dmg[client].DmgSetting = 0;
	}
	if( StrEqual(arg1, "of", false) ) {
		g_dmg[client].DmgSetting = 0;
	}

	if( !StrEqual(arg1, "off", false) && !StrEqual(arg1, "on", false) && !StrEqual(arg1, "0", false) && !StrEqual(arg1, "of", false) ) {
		newval = StringToInt(arg1);

    char newsetting[4];

		if( newval > 8 ) {
			newval = 8;
		}
		if( newval != 0 ) {
			g_dmg[client].DmgSetting = newval;
		}
    
if (newval != 0 && g_dmg[client].DmgSetting == 0) {
    strcopy(newsetting, sizeof(newsetting), "Off");
} else if (newval != 0 && g_dmg[client].DmgSetting > 0) {
    strcopy(newsetting, sizeof(newsetting), "On");
}


		//CPrintToChat(client, "{olive}[VSH 2]{default} The damage tracker is now {lightgreen}%s{default}!", newsetting);
	}

	if (g_dmg[client].DmgSetting > 0)	{
		PrintToChat(client, "[VSH] The damage tracker is displaying the top %i players!", g_dmg[client].DmgSetting);
	}
	else	{
		PrintToChat(client, "[VSH] The damage tracker is now off!", g_dmg[client].DmgSetting);
	}

	if( AreClientCookiesCached(client) ) {
		char strval[6]; IntToString(g_dmg[client].DmgSetting, strval, sizeof(strval));
		g_haledmg_cookie.Set(client, strval);
	}

	char r[4], g[4], b[4], a[4];
	if(args >= 2) {
		GetCmdArg(2, r, sizeof(r));
		if(!StrEqual(r, "_"))
			g_dmg[client].RGBA[RED] = StringToInt(r);
	}

	if(args >= 3) {
		GetCmdArg(3, g, sizeof(g));
		if(!StrEqual(g, "_"))
			g_dmg[client].RGBA[GREEN] = StringToInt(g);
	}
	if(args >= 4) {
		GetCmdArg(4, b, sizeof(b));
		if(!StrEqual(b, "_"))
			g_dmg[client].RGBA[BLUE] = StringToInt(b);
	}
	if(args >= 5) {
		GetCmdArg(5, a, sizeof(a));
		if(!StrEqual(a, "_"))
			g_dmg[client].RGBA[ALPHA] = StringToInt(a);
	}
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] sName)
{
  if (StrEqual(sName, "TF2Items"))
  {
    g_bTF2Items = true;
    
    //We cant allow TF2Items load while GiveNamedItem already hooked due to crash
    if (SDK_IsGiveNamedItemActive())
      PluginStop(true, "[VSH] DO NOT LOAD TF2ITEMS MIDGAME WHILE VSH IS ALREADY LOADED!!!!");
  }
#if defined _updater_included
	if (StrEqual(sName, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}

public void OnLibraryRemoved(const char[] sName)
{
  if (StrEqual(sName, "TF2Items"))
  {
    g_bTF2Items = false;
    
    //TF2Items unloaded with GiveNamedItem unhooked, we can now safely hook GiveNamedItem ourself
    for (int iClient = 1; iClient <= MaxClients; iClient++)
      if (IsClientInGame(iClient))
        SDK_HookGiveNamedItem(iClient);
  }
}


/// UPDATER Stuff
public void OnAllPluginsLoaded() {
#if defined _updater_included
	if(LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
#endif
}

#if defined _updater_included
public Action Updater_OnPluginDownloading() {
	if(!g_ConfigConvar.LookupBool("vsh2_auto_update")) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Updater_OnPluginUpdated() {
	char filename[64]; GetPluginFilename(null, filename, sizeof(filename));
	ServerCommand("sm plugins unload %s", filename);
	ServerCommand("sm plugins load %s", filename);
}
#endif

public void OnNotifyPluginUnloaded(Handle hPlugin)
{
  FuncClass_ClearUnloadedPlugin(hPlugin);
  FuncNative_ClearUnloadedPlugin(hPlugin);
}

public void OnPluginEnd()
{
  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    // Show Health HUD
    int iHideHUD = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
    if (!(iHideHUD & HIDEHUD_HEALTH)) // We turned off Health HUD for boss players.
      iHideHUD ^= HIDEHUD_HEALTH;
    SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHideHUD);

    // Hide Match Status
    iHideHUD = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
    if (!(iHideHUD & HIDEHUD_MATCH_STATUS))
      iHideHUD ^= HIDEHUD_MATCH_STATUS; 
    SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHideHUD);

    if (SaxtonHale_IsValidBoss(iClient))
    {
      SaxtonHaleBase boss = SaxtonHaleBase(iClient);
      boss.DestroyAllClass();
    }
    
    if (IsClientInGame(iClient) && !StrEmpty(g_sBossMusic))
      StopSound(iClient, SNDCHAN_STATIC, g_sBossMusic);
    
    RemoveClientGlowEnt(iClient);
  }
  
  Plugin_Cvars(false);
}

void Plugin_Cvars(bool toggle)
{
  static bool bArenaUseQueue;
  static bool bArenaFirstBlood;
  static bool bForceCamera;

  static int iTeamsUnbalanceLimit;
  static int iDroppedWeaponLifetime;
  static int iDamageDisableSpread;

  static float flScoutHypePepMax;
  static float flFeignDeathActiveDamageScale;
  static float flFeignDeathDamageScale;
  static float flStealthDamageReduction;
  static float flFeignDeathDuration;
  static float flFeignDeathSpeed;

  static bool toggled = false; // Used to avoid a overwrite of default value if toggled twice

  if (toggle && !toggled)
  {
    toggled = true;

    bArenaUseQueue = tf_arena_use_queue.BoolValue;
    tf_arena_use_queue.BoolValue = false;

    bArenaFirstBlood = tf_arena_first_blood.BoolValue;
    tf_arena_first_blood.BoolValue = false;

    bForceCamera = mp_forcecamera.BoolValue;
    mp_forcecamera.BoolValue = false;

    iTeamsUnbalanceLimit = mp_teams_unbalance_limit.IntValue;
    mp_teams_unbalance_limit.IntValue = 0;

    iDroppedWeaponLifetime = tf_dropped_weapon_lifetime.IntValue;
    tf_dropped_weapon_lifetime.IntValue = 0;

    iDamageDisableSpread = tf_damage_disablespread.IntValue;
    tf_damage_disablespread.IntValue = 1;

    flScoutHypePepMax = tf_scout_hype_pep_max.FloatValue;
    tf_scout_hype_pep_max.FloatValue = 100.0;

    flFeignDeathActiveDamageScale = tf_feign_death_activate_damage_scale.FloatValue;
    tf_feign_death_activate_damage_scale.FloatValue = 1.0;

    flFeignDeathDamageScale = tf_feign_death_damage_scale.FloatValue;
    tf_feign_death_damage_scale.FloatValue = 1.0;

    flStealthDamageReduction = tf_stealth_damage_reduction.FloatValue;
    tf_stealth_damage_reduction.FloatValue = 1.0;

    flFeignDeathDuration = tf_feign_death_duration.FloatValue;
    tf_feign_death_duration.FloatValue = 7.0;

    flFeignDeathSpeed = tf_feign_death_speed_duration.FloatValue;
    tf_feign_death_speed_duration.FloatValue = 0.0;
  }
  else if (!toggle && toggled)
  {
    toggled = false;

    tf_arena_use_queue.BoolValue = bArenaUseQueue;
    tf_arena_first_blood.BoolValue = bArenaFirstBlood;
    mp_forcecamera.BoolValue = bForceCamera;

    mp_teams_unbalance_limit.IntValue = iTeamsUnbalanceLimit;
    tf_dropped_weapon_lifetime.IntValue = iDroppedWeaponLifetime;
    tf_damage_disablespread.IntValue = iDamageDisableSpread;

    tf_scout_hype_pep_max.FloatValue = flScoutHypePepMax;
    tf_feign_death_activate_damage_scale.FloatValue = flFeignDeathActiveDamageScale;
    tf_feign_death_damage_scale.FloatValue = flFeignDeathDamageScale;
    tf_stealth_damage_reduction.FloatValue = flStealthDamageReduction;
    tf_feign_death_duration.FloatValue = flFeignDeathDuration;
    tf_feign_death_speed_duration.FloatValue = flFeignDeathSpeed;
  }
}

void PluginStop(bool bError = false, const char[] sError = "")
{
  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    SaxtonHaleBase boss = SaxtonHaleBase(iClient);
    if (boss.bValid)
      boss.DestroyAllClass();
  }
  if (bError)
  {
    PrintToChatAll("\x07FF0000 !!!!ERROR!!! UNEXPECTED CODE EXECUTION DISABLING GAMEMODE..... \n Please contact an admin ASAP!");
    SetFailState(sError);
  }
}

public void OnMapStart()
{
  //Check if the map is a VSH map
  char sMapName[64];
  GetCurrentMap(sMapName, sizeof(sMapName));
  GetMapDisplayName(sMapName, sMapName, sizeof(sMapName));
  
  int iForceLoad = 1;//= g_ConfigConvar.LookupInt("vsh_force_load");
  
  if (iForceLoad == 0)
  {
    g_bEnabled = false;
  } 
  else if (StrContains(sMapName, "pl_", false) != -1)
  {
    Config_Refresh();

    //Precache every bosses/abilities/modifiers registered
    SaxtonHaleBase boss = SaxtonHaleBase(0); //client index doesn't matter
    ArrayList aClass = SaxtonHale_GetAllClass();
    
    int iLength = aClass.Length;
    for (int i = 0; i < iLength; i++)
    {
      char sType[MAX_TYPE_CHAR];
      aClass.GetString(i, sType, sizeof(sType));
      if (boss.StartFunction(sType, "Precache"))
        Call_Finish();
    }
    
    delete aClass;

    for (int i = 1; i <= 4; i++)
    {
      char sBackStabSound[PLATFORM_MAX_PATH];
      Format(sBackStabSound, sizeof(sBackStabSound), "vsh_rewrite/stab0%i.mp3", i);
      PrepareSound(sBackStabSound);
    }

    PrecacheParticleSystem("ExplosionCore_MidAir");
    PrecacheParticleSystem(PARTICLE_GHOST);
    PrecacheParticleSystem("eyeboss_tp_vortex");
    PrecacheParticleSystem("eb_death_vortex01");

    PrecacheSound(SOUND_ALERT);
    PrecacheSound(SOUND_METERFULL);
    PrecacheSound(SOUND_BACKSTAB);
    PrecacheSound(SOUND_DOUBLEDONK);
    PrecacheSound(SOUND_JAR_EXPLODE);
    PrecacheSound(SOUND_NULL);
    
    g_iSpritesLaserbeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
    g_iSpritesGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
    
    CreateTimer(60.0, Timer_WelcomeMessage);

    g_iTotalRoundPlayed = 1; // Set this so VSH logic continues.
    g_bEnabled = true;
    g_bForceLoad = true; // Lazy: Set this so we can load VSH without arena.
  }
  else if ((StrContains(sMapName, "vsh_", false) != -1)
        || (StrContains(sMapName, "vsh_dr_", false) == -1) 
        || (StrContains(sMapName, "ff2_", false) != -1)
        || (StrContains(sMapName, "arena_", false) != -1))
  {
    if (FindEntityByClassname(-1, "tf_logic_arena") == -1)
    {
      g_bEnabled = false;
      return;
    }

    Config_Refresh();

    //Precache every bosses/abilities/modifiers registered
    SaxtonHaleBase boss = SaxtonHaleBase(0); //client index doesn't matter
    ArrayList aClass = SaxtonHale_GetAllClass();
    
    int iLength = aClass.Length;
    for (int i = 0; i < iLength; i++)
    {
      char sType[MAX_TYPE_CHAR];
      aClass.GetString(i, sType, sizeof(sType));
      if (boss.StartFunction(sType, "Precache"))
        Call_Finish();
    }
    
    delete aClass;

    for (int i = 1; i <= 4; i++)
    {
      char sBackStabSound[PLATFORM_MAX_PATH];
      Format(sBackStabSound, sizeof(sBackStabSound), "vsh_rewrite/stab0%i.mp3", i);
      PrepareSound(sBackStabSound);
    }

    PrecacheParticleSystem("ExplosionCore_MidAir");
    PrecacheParticleSystem(PARTICLE_GHOST);
    PrecacheParticleSystem("eyeboss_tp_vortex");
    PrecacheParticleSystem("eb_death_vortex01");

    PrecacheSound(SOUND_ALERT);
    PrecacheSound(SOUND_METERFULL);
    PrecacheSound(SOUND_BACKSTAB);
    PrecacheSound(SOUND_DOUBLEDONK);
    PrecacheSound(SOUND_JAR_EXPLODE);
    PrecacheSound(SOUND_NULL);

    // HaleDMG
    CreateTimer(0.1, Timer_Millisecond, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    
    g_iSpritesLaserbeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
    g_iSpritesGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
    
    Dome_MapStart();
    
    CreateTimer(60.0, Timer_WelcomeMessage);

    g_iTotalRoundPlayed = 0;
    g_bEnabled = true;
    g_bForceLoad = false;
  }
  else
  {
    g_bEnabled = false;
  }

  // Handle Custom Donator stuff
  if (g_bEnabled)
    PrecacheDonatorAudio();
}

public Action Timer_Advertise(Handle timer) 
{
	CreateTimer(180.0, Timer_Advertise);
	PrintToChatAll("%s Type \"!haledmg on\" to display the top 3 players! Type \"!haledmg off\" to turn it off again.", TEXT_TAG);
	return Plugin_Handled;
}

public Action Timer_Millisecond(Handle timer)
{
  if (!g_bEnabled)
    return Plugin_Continue;

  int iTopPlayers[3] = {-1, -1, -1};
  int iTopDamage[3] = {-1, -1, -1};
  char names[3][64];
  int damages[3];

  // Find top 3 players by damage + assist damage
  for (int i = 1; i <= MaxClients; i++)
  {
    if (!IsClientInGame(i))
      continue;

    int iTotalDamage = g_iPlayerDamage[i] + g_iPlayerAssistDamage[i];

    for (int j = 0; j < 3; j++)
    {
      if (iTotalDamage > iTopDamage[j])
      {
        // Shift lower ranks down
        for (int k = 2; k > j; k--)
        {
          iTopDamage[k] = iTopDamage[k - 1];
          iTopPlayers[k] = iTopPlayers[k - 1];
          strcopy(names[k], sizeof(names[k]), names[k - 1]);
        }

        iTopDamage[j] = iTotalDamage;
        iTopPlayers[j] = i;
        GetClientName(i, names[j], sizeof(names[j]));
        break;
      }
    }
  }

  // Prepare damage list string
  char sDamageList[512];
  Format(sDamageList, sizeof(sDamageList),
        "Most damage dealt by:\n" ...
        "1) %d - %s\n" ...
        "2) %d - %s\n" ...
        "3) %d - %s",
        iTopDamage[0], iTopPlayers[0] != -1 ? names[0] : "N/A",
        iTopDamage[1], iTopPlayers[1] != -1 ? names[1] : "N/A",
        iTopDamage[2], iTopPlayers[2] != -1 ? names[2] : "N/A");

  // Show HUD text to all valid clients (non-boss, alive, not pressing scoreboard)
  for (int i = 1; i <= MaxClients; i++)
  {
    if (!IsClientInGame(i))
      continue;

    if (g_dmg[i].DmgSetting > 0)
    {
      if (!SaxtonHale_IsValidBoss(i) && !(GetClientButtons(i) & IN_SCORE))
      {
        SetHudTextParams(0.0, 0.0, 0.2,
                        g_dmg[i].RGBA[RED], g_dmg[i].RGBA[GREEN],
                        g_dmg[i].RGBA[BLUE], g_dmg[i].RGBA[ALPHA]);
        ShowSyncHudText(i, g_hDamageHUD, "%s", sDamageList);
      }
    }
  }

  return Plugin_Continue;
}

public void OnGameFrame()
{
  if (!g_bEnabled) return;
  if (g_iTotalRoundPlayed <= 0) return;

  int iHealthBar = FindEntityByClassname(-1, "monster_resource");
  g_iHealthBarHealth = 0;
  g_iHealthBarMaxHealth = 0;

  if (g_bRoundStarted)
  {
    for (int iClient = 1; iClient <= MaxClients; iClient++)
    {
      SaxtonHaleBase boss = SaxtonHaleBase(iClient);
      if (IsClientInGame(iClient) && TF2_GetClientTeam(iClient) == TFTeam_Boss && boss.bValid && !boss.bMinion)
      {
        if (IsPlayerAlive(iClient))
          g_iHealthBarHealth += GetEntProp(iClient, Prop_Send, "m_iHealth");
        g_iHealthBarMaxHealth += SDK_GetMaxHealth(iClient);
      }
    }

    int healthBarValue = RoundToCeil(float(g_iHealthBarHealth) / float(g_iHealthBarMaxHealth) * 255.0);
    if(healthBarValue > 255) healthBarValue = 255;

    SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", healthBarValue);
  }
  else
    SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
  if (!g_bEnabled || iEntity <= 0 || iEntity > 2048)
    return;
  
  for (int iClient = 1; iClient <= MaxClients; iClient++)
    if (SaxtonHale_IsValidBoss(iClient))
      SaxtonHaleBase(iClient).CallFunction("OnEntityCreated", iEntity, sClassname);
  
  if (StrContains(sClassname, "tf_projectile_healing_bolt") == 0)
  {
    SDKHook(iEntity, SDKHook_StartTouch, Crossbow_OnTouch);
  }
  
  if (StrContains(sClassname, "tf_projectile_") == 0)
  {
    SDKHook(iEntity, SDKHook_StartTouchPost, Tags_OnProjectileTouch);
  }
  else if (strncmp(sClassname, "item_healthkit_", 15) == 0
    || strncmp(sClassname, "item_ammopack_", 14) == 0
    || strcmp(sClassname, "tf_ammo_pack") == 0
    || strcmp(sClassname, "func_regenerate") == 0)
  {
    SDKHook(iEntity, SDKHook_Touch, ItemPack_OnTouch);
  }
  else if (StrEqual(sClassname, "team_control_point_master"))
  {
    SDKHook(iEntity, SDKHook_Spawn, Dome_MasterSpawn);
  }
  else if (StrEqual(sClassname, "trigger_capture_area"))
  {
    SDKHook(iEntity, SDKHook_Spawn, Dome_TriggerSpawn);
    
    SDKHook(iEntity, SDKHook_StartTouch, Dome_TriggerTouch);
    SDKHook(iEntity, SDKHook_Touch, Dome_TriggerTouch);
    SDKHook(iEntity, SDKHook_EndTouch, Dome_TriggerTouch);
  }
  else if (StrEqual(sClassname, "game_end"))
  {
    //Superceding SetWinningTeam causes some maps to force a map change on capture
    AcceptEntityInput(iEntity, "Kill");
  }
  else if (StrContains(sClassname, "obj_") == 0)
  {
    SDKHook(iEntity, SDKHook_OnTakeDamage, Building_OnTakeDamage);
  }
}

public Action Crossbow_OnTouch(int iEntity, int iToucher)
{
  if (iToucher <= 0 || iToucher > MaxClients || !IsClientInGame(iToucher))
    return Plugin_Continue;
  
  int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
  if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
    return Plugin_Continue;
  
  if (GetClientTeam(iClient) == GetClientTeam(iToucher))
  {
    if (SaxtonHale_IsValidBoss(iClient))
    {
      bool bReturn = true;
      Action action = SaxtonHaleBase(iClient).CallFunction("CanHealTarget", iToucher, bReturn);
      if (action >= Plugin_Changed && !bReturn)
      {
        RemoveEntity(iEntity);
        return Plugin_Handled;
      }
      else
      {
        return Plugin_Continue;
      }
    }
    
    if (SaxtonHale_IsValidBoss(iToucher))
    {
      RemoveEntity(iEntity);
      return Plugin_Handled;
    }
  }
  
  return Plugin_Continue;
}

public Action ItemPack_OnTouch(int iEntity, int iToucher)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  if (SaxtonHale_IsValidBoss(iToucher))
  {
    bool bResult;
    SaxtonHaleBase(iToucher).CallFunction("OnPickupTouch", iEntity, bResult);
    
    if (!bResult)
      return Plugin_Handled;
  }
  
  return Plugin_Continue;
}

void Frame_InitVshPreRoundTimer(int iTime)
{
  //Kill the timer created by the game
  int iGameTimer = -1;
  while ((iGameTimer = FindEntityByClassname(iGameTimer, "team_round_timer")) > MaxClients)
  {
    if (GetEntProp(iGameTimer, Prop_Send, "m_bShowInHUD"))
    {
      AcceptEntityInput(iGameTimer, "Kill");
      break;
    }
  }

  //Initiate our timer with our time
  int iTimer = CreateEntityByName("team_round_timer");
  DispatchKeyValue(iTimer, "show_in_hud", "1");
  DispatchSpawn(iTimer);

  SetVariantInt(iTime);
  AcceptEntityInput(iTimer, "SetTime");
  AcceptEntityInput(iTimer, "Resume");
  AcceptEntityInput(iTimer, "Enable");
  SetEntProp(iTimer, Prop_Send, "m_bAutoCountdown", false);

  GameRules_SetPropFloat("m_flStateTransitionTime", float(iTime)+GetGameTime());
  CreateTimer(float(iTime), Timer_EntityCleanup, EntIndexToEntRef(iTimer));

  Event event = CreateEvent("teamplay_update_timer");
  event.Fire();
}

public void Frame_CallJarate(DataPack data)
{
  data.Reset();
  int iClient = GetClientOfUserId(data.ReadCell());
  TagsParams tParams = data.ReadCell();
  delete data;
  
  if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
  {
    delete tParams;
    return;
  }
  
  TagsCore_CallAll(iClient, TagsCall_Jarate, tParams);
  delete tParams;
}

public void TF2_OnConditionAdded(int iClient, TFCond nCond)
{
  if (!g_bEnabled) return;
  if (g_iTotalRoundPlayed <= 0) return;
  
  if (SaxtonHale_IsValidBoss(iClient))
  {
    SaxtonHaleBase(iClient).CallFunction("OnConditionAdded", nCond);

    switch (nCond)
    {
      case TFCond_Cloaked, TFCond_Disguised, TFCond_Stealthed:
      {
        ClearBossEffects(iClient);
      }
      case TFCond_Milked:
      {
        EmitSoundToClient(iClient, SOUND_JAR_EXPLODE);
        PrintCenterText(iClient, "You were milked!");
      }
    }
  }
  
  if (!g_ConfigConvar.LookupInt("vsh_rps_enable"))
  {
    if (GetEntProp(iClient, Prop_Send, "m_iTauntItemDefIndex") == ITEM_ROCK_PAPER_SCISSORS)
    {
      TF2_RemoveCondition(iClient, TFCond_Taunting);
      PrintToChat(iClient, "%s%s Rock, Paper, Scissors taunt is disabled in this gamemode", TEXT_TAG, TEXT_ERROR);
    }
  }
}

public void TF2_OnConditionRemoved(int iClient, TFCond nCond)
{
  if (!g_bEnabled) return;
  if (g_iTotalRoundPlayed <= 0) return;
  
  if (SaxtonHale_IsValidBoss(iClient))
  {
    SaxtonHaleBase(iClient).CallFunction("OnConditionRemoved", nCond);

    switch (nCond)
    {
      case TFCond_Cloaked, TFCond_Disguised, TFCond_Stealthed:
      {
        ApplyBossEffects(SaxtonHaleBase(iClient));
      }
    }
  }
  
  if (nCond == TFCond_Disguising || nCond == TFCond_Disguised)
    UpdateClientGlowEnt(iClient);
}

// Here is where i'd add our donator sounds.
public Action Timer_RoundStartSound(Handle hTimer, int iClient)
{
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (0 < iClient <= MaxClients && IsClientInGame(iClient) && boss.bValid)
  {
    // Donator only
    if (DonatorSound_Play(iClient))
      return Plugin_Continue;
    
    char sSound[255];
    boss.CallFunction("GetSound", sSound, sizeof(sSound), VSHSound_RoundStart);
    if (!StrEmpty(sSound))
      BroadcastSoundToTeam(TFTeam_Spectator, sSound);
  }
  
  return Plugin_Continue;
}

public Action Timer_Music(Handle hTimer, SaxtonHaleBase boss)
{
  if (g_hTimerBossMusic != hTimer)
    return Plugin_Stop;
  
  if (!boss.bValid)
  {
    g_hTimerBossMusic = null;
    return Plugin_Stop;
  }
  
  if (StrEmpty(g_sBossMusic))
    return Plugin_Stop;

  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    if (IsClientInGame(iClient))
    {
      //Stop current music before playing another one
      StopSound(iClient, SNDCHAN_STATIC, g_sBossMusic);
      
      if (Preferences_Get(iClient, VSHPreferences_Music))
        EmitSoundToClient(iClient, g_sBossMusic, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
    }
  }

  return Plugin_Continue;
}

public Action Timer_WelcomeMessage(Handle hTimer)
{
  if (!g_bEnabled)
    return Plugin_Stop;
  
  PrintToChatAll("%s Welcome to \x079EC34FVersus Saxton Hale\x01: \x07FB6542Rewrite!\x01 \nType \x079EC34F/vsh\x01 for more info.", TEXT_TAG);
  return Plugin_Continue;
}

public Action Timer_EntityCleanup(Handle hTimer, int iRef)
{
  int iEntity = EntRefToEntIndex(iRef);
  if(iEntity > MaxClients)
    AcceptEntityInput(iEntity, "Kill");
  return Plugin_Handled;
}

public void OnClientConnected(int iClient)
{
  g_iPlayerDamage[iClient] = 0;
  g_iPlayerAssistDamage[iClient] = 0;
  g_iClientFlags[iClient] = 0;
  g_iClientOwner[iClient] = 0;
  
  for (int i = 1; i <= MaxClients; i++)
  {
    g_bClientAreaOfEffect[iClient][i] = false;
    g_bClientAreaOfEffect[i][iClient] = false;
  }
  
  ClassLimit_SetMainClass(iClient, TFClass_Unknown);
  ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
  
  //-1 as unknown
  Preferences_SetAll(iClient, -1);
  Queue_SetPlayerPoints(iClient, -1);
}

public void OnClientPutInServer(int iClient)
{
  SDK_HookGetMaxHealth(iClient);
  SDK_HookGiveNamedItem(iClient);
  SDKHook(iClient, SDKHook_PreThink, Client_OnThink);
  SDKHook(iClient, SDKHook_OnTakeDamageAlive, Client_OnTakeDamageAlive);
  SDKHook(iClient, SDKHook_OnTakeDamage, Client_OnTakeDamage);
  SDKHook(iClient, SDKHook_OnTakeDamagePost, Client_OnTakeDamagePost);
  SDKHook(iClient, SDKHook_StartTouch, Client_OnStartTouch);
  SDKHook(iClient, SDKHook_WeaponSwitchPost, Client_OnWeaponSwitchPost);
  
  // HaleDMG
  g_dmg[iClient].DmgSetting = 0;
	g_dmg[iClient].RGBA[RED] = 255;
	g_dmg[iClient].RGBA[GREEN] = 90;
	g_dmg[iClient].RGBA[BLUE] = 30;
	g_dmg[iClient].RGBA[ALPHA] = 255;

	if (AreClientCookiesCached(iClient)) 
  {
		char setting[2]; g_haledmg_cookie.Get(iClient, setting, sizeof(setting));
		g_dmg[iClient].DmgSetting = StringToInt(setting);
	}

  Cookies_OnClientJoin(iClient);
  
  // Disable Ugly HUD
  //int iHideHUD = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
  //iHideHUD ^= HIDEHUD_MATCH_STATUS;
  //SetEntProp(iClient, Prop_Send, "m_iHideHUD", iHideHUD);
}

public void OnClientPostAdminCheck(int iClient)
{
  AdminId iAdmin = GetUserAdmin(iClient);
  if (iAdmin.HasFlag(Admin_RCON) || iAdmin.HasFlag(Admin_Root))
    Client_AddFlag(iClient, ClientFlags_Admin);
}

public void OnClientDisconnect(int iClient)
{
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  
  if (boss.bValid)
  {
    boss.DestroyAllClass();
    CheckForceAttackWin(iClient);
  }

  g_iClientFlags[iClient] = 0;

  SDK_UnhookGiveNamedItem(iClient);

  ClassLimit_SetMainClass(iClient, TFClass_Unknown);
  ClassLimit_SetDesiredClass(iClient, TFClass_Unknown);
  
  Preferences_SetAll(iClient, -1);
  Queue_SetPlayerPoints(iClient, -1);
  
  NextBoss_DeleteClient(iClient);
  
  RemoveClientGlowEnt(iClient);
}

public void OnClientDisconnect_Post(int iClient)
{
  TagsCore_RefreshClient(iClient);	//Free the memory
}

public void Client_OnThink(int iClient)
{
  if (!g_bEnabled) return;
  
  Dome_OnThink(iClient);
  
  if (g_iTotalRoundPlayed <= 0) return;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
    boss.CallFunction("OnThink");
  else
  {
    Tags_OnThink(iClient);
    
    TFClassType nClass = TF2_GetPlayerClass(iClient);
    
    int iActiveWep = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");

    int iIndex = -1;
    int iSlot = -1;
    if (IsValidEntity(iActiveWep))
    {
      iIndex = GetEntProp(iActiveWep, Prop_Send, "m_iItemDefinitionIndex");
      iSlot = TF2_GetItemSlot(iIndex, nClass);
    }

    if (0 <= iSlot < sizeof(g_ConfigClass[]) && IsValidEntity(iActiveWep) && !TF2_IsPlayerInCondition(iClient, TFCond_Disguised) && !TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
    {
      //Get amount of active players
      int iPlayerCount = SaxtonHale_GetAliveAttackPlayers();
      
      //Check minicrit from index
      int iMinicrit = g_ConfigIndex.IsMinicrit(iIndex);
      if (iMinicrit == 1)
      {
        TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
      }
      else if (iMinicrit != 0)	//not 0 in config
      {
        //Check minicrit from slot
        iMinicrit = g_ConfigClass[nClass][iSlot].IsMinicrit();
        if (iMinicrit == 1)
          TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
        else if (iMinicrit != 0 && iPlayerCount <= 3)	//Give minicrit if less than 3 players and not 0 in config
          TF2_AddCondition(iClient, TFCond_Buffed, 0.05);
      }
      
      //Check crit from index
      int iCrit = g_ConfigIndex.IsCrit(iIndex);
      if (iCrit == 1)
      {
        TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
      }
      else if (iCrit != 0)	//not 0 in config
      {
        //Check minicrit from slot
        iCrit = g_ConfigClass[nClass][iSlot].IsCrit();
        if (iCrit == 1)
          TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
        else if (iCrit != 0 && iPlayerCount <= 1)	//Give crit if last man and not 0 in config
          TF2_AddCondition(iClient, TFCond_CritOnDamage, 0.05);
      }
    }
  }
  
  Hud_Think(iClient);
}

public Action Client_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  Action finalAction = Plugin_Continue;
  
  if (0 < victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) > 1)
  {
    SaxtonHaleBase bossVictim = SaxtonHaleBase(victim);
    SaxtonHaleBase bossAttacker = SaxtonHaleBase(attacker);
    
    Action action = Plugin_Continue;
    
    if (bossVictim.bValid)
    {
      action = bossVictim.CallFunction("OnTakeDamage", attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
      if (action > finalAction)
        finalAction = action;
    }
    
    if (0 < attacker <= MaxClients && victim != attacker && bossAttacker.bValid)
    {
      action = bossAttacker.CallFunction("OnAttackDamage", victim, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
      if (action > finalAction)
        finalAction = action;
    }
    
    //Stop immediately if returning Plugin_Stop
    if (finalAction == Plugin_Stop)
      return finalAction;
    
    g_iTelefragBuilder = 0;
    int iBuilder;
    if (0 < attacker <= MaxClients && IsClientInGame(attacker))
    {
      if (!bossAttacker.bValid)
      {
        if (bossVictim.bValid && !bossVictim.bMinion)
        {
          if (damagecustom == TF_CUSTOM_TELEFRAG && !TF2_IsUbercharged(victim))
          {
            int iTelefragDamage = g_ConfigConvar.LookupInt("vsh_telefrag_damage");
            damage = float(iTelefragDamage);
            damagetype &= ~DMG_CRIT;
            
            PrintCenterText(attacker, "TELEFRAG! You are a pro.");
            PrintCenterText(victim, "TELEFRAG! Be careful around quantum tunneling devices!");
            PrintToChatAll("%s[VSH] %s%N %sjust %sTELEFRAGGED %s%N %sfor 9001 dmg", COLOR_OLIVE, COLOR_RED, attacker, COLOR_DEFAULT, COLOR_YELLOW, COLOR_BLUE, victim, COLOR_DEFAULT);  

            //Try to retrieve the entity under the player, and hopefully this is the teleporter
            int iGroundEntity = GetEntPropEnt(attacker, Prop_Send, "m_hGroundEntity");
            if (iGroundEntity > MaxClients)
            {
              char strGroundEntity[32];
              GetEdictClassname(iGroundEntity, strGroundEntity, sizeof(strGroundEntity));
              if (strcmp(strGroundEntity, "obj_teleporter") == 0)
              {
                iBuilder = GetEntPropEnt(iGroundEntity, Prop_Send, "m_hBuilder");
                if (0 < iBuilder <= MaxClients && IsClientInGame(iBuilder))
                {
                  if (attacker == iBuilder)
                    iBuilder = 0;
                }
                else
                {
                  iBuilder = 0;
                }
              }
            }
            
            Forward_TeleportDamage(victim, attacker, iBuilder);
            g_iTelefragBuilder = iBuilder;
            finalAction = Plugin_Changed;
          }
        }
      }
    }
    
    // Call damage tags
    action = TagsDamage_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
    if (action > finalAction)
      finalAction = action;
  }
  
  if (victim != attacker && SaxtonHale_IsValidAttack(attacker) && weapon != INVALID_ENT_REFERENCE && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
  {
    TFClassType nClass = TF2_GetPlayerClass(attacker);
    int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    int iSlot = TF2_GetItemSlot(iIndex, nClass);
    
    if (0 <= iSlot < sizeof(g_ConfigClass[]))
    {
      int iIgnoreFalloff = g_ConfigIndex.IgnoreFalloff(iIndex);
      if (iIgnoreFalloff == -1)
        iIgnoreFalloff = g_ConfigClass[nClass][iSlot].IgnoreFalloff();
      
      if (iIgnoreFalloff == 1)
        TF2_AddCondition(attacker, TFCond_RunePrecision, 0.05);
    }
  }
  
  return finalAction;
}

public void Client_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
  if (!g_bEnabled) return;
  if (g_iTotalRoundPlayed <= 0) return;
  
  if (victim != attacker && SaxtonHale_IsValidAttack(attacker) && weapon != INVALID_ENT_REFERENCE && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
  {
    TFClassType nClass = TF2_GetPlayerClass(attacker);
    int iIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    int iSlot = TF2_GetItemSlot(iIndex, nClass);
    
    if (0 <= iSlot < sizeof(g_ConfigClass[]))
    {
      int iIgnoreFalloff = g_ConfigIndex.IgnoreFalloff(iIndex);
      if (iIgnoreFalloff == -1)
        iIgnoreFalloff = g_ConfigClass[nClass][iSlot].IgnoreFalloff();
      
      if (iIgnoreFalloff == 1)
        TF2_RemoveCondition(attacker, TFCond_RunePrecision);
    }
  }
}

public Action Client_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  Action finalAction = Plugin_Continue;
  
  if (0 < victim <= MaxClients && IsClientInGame(victim) && GetClientTeam(victim) > 1)
  {
    SaxtonHaleBase bossVictim = SaxtonHaleBase(victim);
    SaxtonHaleBase bossAttacker = SaxtonHaleBase(attacker);
    
    Action action = Plugin_Continue;
    
    if (bossVictim.bValid)
    {
      action = bossVictim.CallFunction("OnTakeDamageAlive", attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
      if (action > finalAction)
        finalAction = action;
    }
    
    if (0 < attacker <= MaxClients && victim != attacker && bossAttacker.bValid)
    {
      action = bossAttacker.CallFunction("OnAttackDamageAlive", victim, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
      if (action > finalAction)
        finalAction = action;
    }
    
    // Stop immediately if returning Plugin_Stop
    if (finalAction == Plugin_Stop)
      return finalAction;
    
    // Call damage tags
    action = TagsDamage_OnTakeDamageAlive(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
    if (action > finalAction)
      finalAction = action;
    
    // Give telefrag assists after tags modified it
    if (damagecustom == TF_CUSTOM_TELEFRAG)
    {
      int iBuilder = g_iTelefragBuilder;
      if (iBuilder)
        g_iPlayerAssistDamage[iBuilder] += RoundToNearest(damage);
    }
  }
  
  return finalAction;
}

public Action Client_OnStartTouch(int iClient, int iToucher)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  
  if (0 < iClient <= MaxClients && boss.bValid)
    return boss.CallFunction("OnStartTouch", iToucher);
  
  return Plugin_Continue;
}

public Action Client_OnWeaponSwitchPost(int iClient, int iWeapon)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  
  if (0 < iClient <= MaxClients && boss.bValid)
    return boss.CallFunction("OnWeaponSwitchPost", iWeapon);
  
  return Plugin_Continue;
}

public Action Building_OnTakeDamage(int building, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  SaxtonHaleBase bossAttacker = SaxtonHaleBase(attacker);
  
  if (0 < attacker <= MaxClients && bossAttacker.bValid)
    return bossAttacker.CallFunction("OnAttackBuilding", building, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
    
  return Plugin_Continue;
}

public bool BossTargetFilter(char[] sPattern, ArrayList aClients)
{
  bool bTargetBoss = StrContains(sPattern, "@!") == -1;
  
  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    if (IsClientInGame(iClient) && aClients.FindValue(iClient) == -1)
    {
      bool bIsBoss = SaxtonHale_IsValidBoss(iClient, false);
      
      if (bTargetBoss && bIsBoss)
        aClients.Push(iClient);
      else if (!bTargetBoss && !bIsBoss)
        aClients.Push(iClient);
    }
  }
  
  return true;
}

public Action OnClientCommandKeyValues(int iClient, KeyValues kv)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return Plugin_Continue;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
  {
    char sCommand[64];
    kv.GetSectionName(sCommand, sizeof(sCommand));
    
    return boss.CallFunction("OnCommandKeyValues", sCommand);
  }
  
  return Plugin_Continue;
}

public Action OnPlayerRunCmd(int iClient,int &buttons,int &impulse, float vel[3], float angles[3],int &weapon,int &subtype,int &cmdnum,int &tickcount,int &seed,int mouse[2])
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return Plugin_Continue;

  for (int i = 0; i < MAX_BUTTONS; i++)
  {
    int button = (1 << i);
    if ((buttons & button) && !(g_iPlayerLastButtons[iClient] & button))
      Client_OnButtonPress(iClient, button);
    else if (!(buttons & button) && (g_iPlayerLastButtons[iClient] & button))
      Client_OnButtonRelease(iClient, button);
  }

  g_iPlayerLastButtons[iClient] = buttons;
  Client_OnButton(iClient, buttons);

  if (g_iPlayerLastButtons[iClient] != buttons)
    return Plugin_Changed;

  return Plugin_Continue;
}

void Client_OnButton(int iClient, int &buttons)
{
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
    boss.CallFunction("OnButton", buttons);
  else
    Tags_OnButton(iClient, buttons);
}

void Client_OnButtonPress(int iClient, int button)
{
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
    boss.CallFunction("OnButtonPress", button);
}

void Client_OnButtonRelease(int iClient, int button)
{
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
    boss.CallFunction("OnButtonRelease", button);
}






// UPD: 12.11.2015
// SPELLS DEFINES
#define FIREBALL    0   // Done
#define BATS        1   // Done
#define PUMPKIN     2   // Done
#define TELE        3   // Done
#define LIGHTNING   4   // Done
#define BOSS        5   // Done
#define METEOR      6   // Done
#define ZOMBIEH     7   // Done
#define ZOMBIE      8
#define PUMPKIN2    9

stock int ShootProjectile(int client, int spell)
{
  float vAngles[3]; // original
  float vPosition[3]; // original
  GetClientEyeAngles(client, vAngles);
  GetClientEyePosition(client, vPosition);
  char strEntname[45] = "";
  switch(spell)
  {
    case FIREBALL: 		strEntname = "tf_projectile_spellfireball";
    case LIGHTNING: 	strEntname = "tf_projectile_lightningorb";
    case PUMPKIN: 		strEntname = "tf_projectile_spellmirv";
    case PUMPKIN2: 		strEntname = "tf_projectile_spellpumpkin";
    case BATS: 			strEntname = "tf_projectile_spellbats";
    case METEOR: 		strEntname = "tf_projectile_spellmeteorshower";
    case TELE: 			strEntname = "tf_projectile_spelltransposeteleport";
    case BOSS:			strEntname = "tf_projectile_spellspawnboss";
    case ZOMBIEH:		strEntname = "tf_projectile_spellspawnhorde";
    case ZOMBIE:		strEntname = "tf_projectile_spellspawnzombie";
  }
  int iTeam = GetClientTeam(client);
  int iSpell = CreateEntityByName(strEntname);
  
  if(!IsValidEntity(iSpell))
    return -1;
  
  float vVelocity[3];
  float vBuffer[3];
  
  GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
  vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
  vVelocity[1] = vBuffer[1]*1100.0;
  vVelocity[2] = vBuffer[2]*1100.0;
  SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", client);
  SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
  SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
  SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));

  TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);

  SetVariantInt(iTeam);
  AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
  SetVariantInt(iTeam);
  AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
  DispatchSpawn(iSpell);
  TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);

  return iSpell;
}

stock int GetActiveWep(const int client) {
  int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
  return( IsValidEntity(weapon) ) ? weapon : -1;
}

stock bool IsWeaponSlotActive(const int client, const int slot) {
  return GetPlayerWeaponSlot(client, slot) == GetActiveWep(client);
}

public Action TF2_CalcIsAttackCritical(int iClient, int iWeapon, char[] sWepClassName, bool &bResult)
{
  if (!g_bEnabled) return Plugin_Continue;
  if (g_iTotalRoundPlayed <= 0) return Plugin_Continue;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
  {
    return boss.CallFunction("OnAttackCritical", iWeapon, bResult);
  }
  else
  {
    int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
    int iSlot = TF2_GetItemSlot(iIndex, TF2_GetPlayerClass(iClient));

    
    /// Sun on a Stick - fireball
    if( iIndex == 349 ) {
    if( TF2_GetPlayerClass(iClient)==TFClass_Scout 
      && IsWeaponSlotActive(iClient, TFWeaponSlot_Melee) ) {
      ShootProjectile(iClient, FIREBALL);
    }
  }

    if (WeaponSlot_Primary <= iSlot <= WeaponSlot_BuilderEngie)
    {
      TagsParams tParams = new TagsParams();
      TagsCore_CallSlot(iClient, TagsCall_Attack, iSlot, tParams);
      
      //Override crit result
      int iResult;
      if (tParams.GetIntEx("attackcrit", iResult))
      {
        bResult = !!iResult;
        delete tParams;
        return Plugin_Changed;
      }
      
      delete tParams;
    }
    
    return Plugin_Continue;
  }
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
  if (0 < entity <= MaxClients && IsClientInGame(entity))
  {
    SaxtonHaleBase boss = SaxtonHaleBase(entity);
    if (boss.bValid)
      return boss.CallFunction("OnSoundPlayed", clients, numClients, sample, channel, volume, level, pitch, flags, soundEntry, seed);
  }
  return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
  return GiveNamedItem(client, classname, itemDefIndex);
}

Action GiveNamedItem(int iClient, const char[] sClassname, int iIndex)
{
  if (!g_bEnabled) return Plugin_Continue;
  
  SaxtonHaleBase boss = SaxtonHaleBase(iClient);
  if (boss.bValid)
    return boss.CallFunction("OnGiveNamedItem", sClassname, iIndex);
  else if (g_ConfigIndex.IsRestricted(iIndex))
    return Plugin_Handled;
  
  return Plugin_Continue;
}

void UpdateClientGlowEnt(int iClient)
{
  static char sClassModels[][PLATFORM_MAX_PATH] = {	//Do we need to precache this? or does TF2 already precache it
    "",
    "models/player/scout.mdl",
    "models/player/sniper.mdl",
    "models/player/soldier.mdl",
    "models/player/demo.mdl",
    "models/player/medic.mdl",
    "models/player/heavy.mdl",
    "models/player/pyro.mdl",
    "models/player/spy.mdl",
    "models/player/engineer.mdl",
  };
  
  static int iClientGlowEnt[MAXPLAYERS];
  if (!iClientGlowEnt[iClient])
    iClientGlowEnt[iClient] = INVALID_ENT_REFERENCE;
  
  char sModel[PLATFORM_MAX_PATH];
  if (TF2_IsPlayerInCondition(iClient, TFCond_Disguised))
    sModel = sClassModels[GetEntProp(iClient, Prop_Send, "m_nDisguiseClass")];
  else
    GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
  
  if (!IsValidEntity(iClientGlowEnt[iClient]))
    iClientGlowEnt[iClient] = TF2_CreateTransmitGlow(iClient, sModel, Transmit_PlayerGlow);
  else
    SetEntityModel(iClientGlowEnt[iClient], sModel);
}

public Action Transmit_PlayerGlow(int iEntity, int iTarget)
{
  int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hParent");
  if (iClient == INVALID_ENT_REFERENCE)
  {
    RemoveEntity(iEntity);
    return Plugin_Stop;
  }
  
  if (!SaxtonHale_IsValidBoss(iTarget) || !SaxtonHale_IsValidAttack(iClient) || TF2_GetClientTeam(iClient) == TF2_GetClientTeam(iTarget))
    return Plugin_Stop;
  
  int iScore = SaxtonHale_GetScore(iClient);
  bool bLastMan = true;
  
  for (int i = 1; i <= MaxClients; i++)
  {
    if (iClient != i && SaxtonHale_IsValidAttack(i) && IsPlayerAlive(i))
    {
      bLastMan = false;
      if (SaxtonHale_GetScore(i) > iScore)
        return Plugin_Stop;	//Theres someone with bigger score than us
    }
  }
  
  if (!bLastMan && iScore == 0)
    return Plugin_Stop;
  
  //Were MVP baby!
  return Plugin_Continue;
}

void RemoveClientGlowEnt(int iClient)
{
  //Find any existing glow parented to client to delete
  int iGlow = INVALID_ENT_REFERENCE;
  while ((iGlow = FindEntityByClassname(iGlow, "tf_taunt_prop")) != INVALID_ENT_REFERENCE)
  {
    if (GetEntPropEnt(iGlow, Prop_Data, "m_hParent") == iClient)
      RemoveEntity(iGlow);
  }
}

public Action Timer_DestroyLight(Handle hTimer, int iRef)
{
  int iLight = EntRefToEntIndex(iRef);
  if (iLight > MaxClients)
  {
    AcceptEntityInput(iLight, "TurnOff");
    RequestFrame(Frame_KillLight, iRef);
  }
  
  return Plugin_Continue;
}

void Frame_KillLight(int iRef)
{
  int iLight = EntRefToEntIndex(iRef);
  if (iLight > MaxClients)
    AcceptEntityInput(iLight, "Kill");
}

// Allow Boss to take teleporters - Taken from AnyTeleporter
public Action TF2_OnPlayerTeleport(int iClient, int iTeleporter, bool& result) 
{
  result = true;
  return Plugin_Changed;
}