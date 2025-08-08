#define BUNNY_MODEL "models/player/new_saxton_hale/easter_demo/new_easter_demo_v3.mdl"
#define BUNNY_EGG		"models/player/saxton_hale/w_easteregg.mdl"

/// Easter Bunny voicelines
static char g_strBunnyRoundStart[][] = {
  "vo/demoman_gibberish03.mp3",
  "vo/demoman_gibberish11.mp3"
};

static char g_strBunnyWin[][] = {
  "vo/demoman_gibberish01.mp3",
  "vo/demoman_gibberish12.mp3",
  "vo/demoman_cheers02.mp3",
  "vo/demoman_cheers03.mp3",
  "vo/demoman_cheers06.mp3",
  "vo/demoman_cheers07.mp3",
  "vo/demoman_cheers08.mp3",
  "vo/taunts/demoman_taunts12.mp3"
};

static char g_strBunnyLose[][] = {
  "vo/demoman_gibberish04.mp3",
  "vo/demoman_gibberish10.mp3",
  "vo/demoman_jeers03.mp3",
  "vo/demoman_jeers06.mp3",
  "vo/demoman_jeers07.mp3",
  "vo/demoman_jeers08.mp3"
};

static char g_strBunnyRage[][] = {
  "vo/demoman_positivevocalization03.mp3",
  "vo/demoman_dominationscout05.mp3",
  "vo/demoman_cheers02.mp3"
};

static char g_strBunnyJump[][] = {
  "vo/demoman_gibberish07.mp3",
  "vo/demoman_gibberish08.mp3",
  "vo/demoman_laughshort01.mp3",
  "vo/demoman_positivevocalization04.mp3"
};

static char g_strBunnyKill[][] = {
  "vo/demoman_gibberish09.mp3",
  "vo/demoman_cheers02.mp3",
  "vo/demoman_cheers07.mp3",
  "vo/demoman_positivevocalization03.mp3"
};

static char g_strBunnyLastMan[][] = {
  "vo/taunts/demoman_taunts05.mp3",
  "vo/taunts/demoman_taunts04.mp3",
  "vo/demoman_specialcompleted07.mp3"
};

static char g_strBunnyBackStabbed[][] = {
  "vo/demoman_sf12_badmagic01.mp3",
  "vo/demoman_sf12_badmagic07.mp3",
  "vo/demoman_sf12_badmagic10.mp3"
};

// Unused
static char BunnySpree[][] = {
  "vo/demoman_gibberish05.mp3",
  "vo/demoman_gibberish06.mp3",
  "vo/demoman_gibberish09.mp3",
  "vo/demoman_gibberish11.mp3",
  "vo/demoman_gibberish13.mp3",
  "vo/demoman_autodejectedtie01.mp3"
};

static char BunnyRandomVoice[][] = {
  "vo/demoman_positivevocalization03.mp3",
  "vo/demoman_jeers08.mp3",
  "vo/demoman_gibberish03.mp3",
  "vo/demoman_cheers07.mp3",
  "vo/demoman_sf12_badmagic01.mp3",
  "vo/burp02.mp3",
  "vo/burp03.mp3",
  "vo/burp04.mp3",
  "vo/burp05.mp3",
  "vo/burp06.mp3",
  "vo/burp07.mp3"
};


stock int AttachProjectileModel(const int entity, const char[] strModel, char[] strAnim = "") {
	if( !IsValidEntity(entity) ) {
		return -1;
	}
	int model = CreateEntityByName("prop_dynamic");
	if( IsValidEntity(model) ) {
		float pos[3], ang[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
		TeleportEntity(model, pos, ang, NULL_VECTOR);
		DispatchKeyValue(model, "model", strModel);
		DispatchSpawn(model);
		SetVariantString("!activator");
		AcceptEntityInput(model, "SetParent", entity, model, 0);
		if( strAnim[0] != '\0' ) {
			SetVariantString(strAnim);
			AcceptEntityInput(model, "SetDefaultAnimation");
			SetVariantString(strAnim);
			AcceptEntityInput(model, "SetAnimation");
		}
		SetEntPropEnt(model, Prop_Send, "m_hOwnerEntity", entity);
		return model;
	}
	else {
		LogError("(AttachProjectileModel): Could not create prop_dynamic");
	}
	return -1;
}

stock void SpawnManyAmmoPacks(const int client, const char[] model, int skin=0, int num=14, float offsz = 30.0)
{
	float pos[3], vel[3], ang[3];
	ang[0] = 90.0;
	ang[1] = 0.0;
	ang[2] = 0.0;
	GetClientAbsOrigin(client, pos);
	pos[2] += offsz;
	for( int i=0; i<num; i++ ) {
		vel[0] = GetRandomFloat(-400.0, 400.0);
		vel[1] = GetRandomFloat(-400.0, 400.0);
		vel[2] = GetRandomFloat(300.0, 500.0);
		pos[0] += GetRandomFloat(-5.0, 5.0);
		pos[1] += GetRandomFloat(-5.0, 5.0);
		int ent = CreateEntityByName("tf_ammo_pack");
		if( !IsValidEntity(ent) )
			continue;
		SetEntityModel(ent, model);
		DispatchKeyValue(ent, "OnPlayerTouch", "!self,Kill,,0,-1"); /// for safety, but it shouldn't act like a normal ammopack
		SetEntProp(ent, Prop_Send, "m_nSkin", skin);
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
		SetEntProp(ent, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", TFTeam_Attack);
		TeleportEntity(ent, pos, ang, vel);
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, ang, vel);
		SetEntProp(ent, Prop_Data, "m_iHealth", 900);
		int offs = GetEntSendPropOffs(ent, "m_vecInitialVelocity", true);
		SetEntData(ent, offs-4, 1, _, true);
	}
}

public Action Timer_SetEggBomb(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if( FileExists(BUNNY_EGG, true) && IsModelPrecached(BUNNY_EGG) && IsValidEntity(entity) ) {
		int att = AttachProjectileModel(entity, BUNNY_EGG);
		SetEntProp(att, Prop_Send, "m_nSkin", 0);
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
	}
	return Plugin_Continue;
}



public void Bunny_Create(SaxtonHaleBase boss)
{
  boss.CreateClass("BraveJump");
  
  boss.CreateClass("ScareRage");
  boss.SetPropFloat("ScareRage", "Radius", 200.0);
  
  boss.iHealthPerPlayer = 600;
  boss.flHealthExponential = 1.05;
  boss.nClass = TFClass_DemoMan;
  boss.iMaxRageDamage = 2500;
}

public void Bunny_GetBossName(SaxtonHaleBase boss, char[] sName, int length)
{
  strcopy(sName, length, "Easter Bunny");
}

public void Bunny_GetBossInfo(SaxtonHaleBase boss, char[] sInfo, int length)
{
  StrCat(sInfo, length, "\nHealth: Medium");
  StrCat(sInfo, length, "\n ");
  StrCat(sInfo, length, "\nAbilities");
  StrCat(sInfo, length, "\n- Brave Jump");
  StrCat(sInfo, length, "\n- On Kill Spawns Crit Eggs");
  StrCat(sInfo, length, "\n ");
  StrCat(sInfo, length, "\nRage");
  StrCat(sInfo, length, "\n- Damage requirement: 2500");
  StrCat(sInfo, length, "\n- Shoots Crit Eggs!");
  StrCat(sInfo, length, "\n- Scares players at close range for 5 seconds");
  StrCat(sInfo, length, "\n- 200%% Rage: longer range scare and extends duration to 7.5 seconds");
}

public void Bunny_OnEntityCreated(SaxtonHaleBase boss, int iEntity, const char[] sClassname)
{
  if (TF2_GetClientTeam(boss.iClient) == TFTeam_Boss && boss.bValid && strcmp(sClassname, "tf_projectile_pipe") == 0)
  {
    if (FileExists(BUNNY_EGG, true) && IsModelPrecached(BUNNY_EGG) && IsValidEntity(iEntity)) {
      int att = AttachProjectileModel(iEntity, BUNNY_EGG);
		  SetEntProp(att, Prop_Send, "m_nSkin", 0);
		  SetEntityRenderMode(iEntity, RENDER_TRANSCOLOR);
		  SetEntityRenderColor(iEntity, 255, 255, 255, 0);
	  }
  }
}

public void Bunny_OnSpawn(SaxtonHaleBase boss)
{
  int iClient = boss.iClient;
  int iWeapon;
  char attribs[128];

  Format(attribs, sizeof(attribs), "68 ; 2.0 ; 2 ; 3.0 ; 326 ; 1.3 ; 275 ; 1");
  iWeapon = boss.CallFunction("CreateWeapon", 609, "tf_weapon_bottle", 100, TFQual_Collectors, attribs);
  if (iWeapon > MaxClients)
    SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
  /*
  The Scottish Handshake attributes:
  2: damage bonus 
  68: increase player capture value 
  326: increased jump height 
  275: cancel falling damage 
  */
}

public void Bunny_GetSound(SaxtonHaleBase boss, char[] sSound, int length, SaxtonHaleSound iSoundType)
{
  switch (iSoundType)
  {
    case VSHSound_RoundStart: strcopy(sSound, length, g_strBunnyRoundStart[GetRandomInt(0,sizeof(g_strBunnyRoundStart)-1)]);
    case VSHSound_Win: strcopy(sSound, length, g_strBunnyWin[GetRandomInt(0,sizeof(g_strBunnyWin)-1)]);
    case VSHSound_Lose: strcopy(sSound, length, g_strBunnyLose[GetRandomInt(0,sizeof(g_strBunnyLose)-1)]);
    case VSHSound_Rage: strcopy(sSound, length, g_strBunnyRage[GetRandomInt(0,sizeof(g_strBunnyRage)-1)]);
    case VSHSound_Lastman: strcopy(sSound, length, g_strBunnyLastMan[GetRandomInt(0,sizeof(g_strBunnyLastMan)-1)]);
    case VSHSound_Backstab: strcopy(sSound, length, g_strBunnyBackStabbed[GetRandomInt(0,sizeof(g_strBunnyBackStabbed)-1)]);
  }
}

public void Bunny_GetSoundKill(SaxtonHaleBase boss, char[] sSound, int length, TFClassType nClass)
{
  strcopy(sSound, length, g_strBunnyKill[GetRandomInt(0,sizeof(g_strBunnyKill)-1)]);
}

public void Bunny_OnPlayerKilled(SaxtonHaleBase boss, Event event, int iVictim)
{
  SpawnManyAmmoPacks(iVictim, BUNNY_EGG, 1);
}

public void Bunny_GetSoundAbility(SaxtonHaleBase boss, char[] sSound, int length, const char[] sType)
{
  if (strcmp(sType, "BraveJump") == 0)
    strcopy(sSound, length, g_strBunnyJump[GetRandomInt(0,sizeof(g_strBunnyJump)-1)]);
}


public void Bunny_OnThink(SaxtonHaleBase boss)
{
  
}

public void Bunny_GetHudInfo(SaxtonHaleBase boss, char[] sMessage, int iLength, int iColor[4])
{

}

public void Bunny_OnRage(SaxtonHaleBase boss)
{
  int iClient = boss.iClient;
  int iWeapon;
  char attribs[128];

  TF2_AddCondition(iClient, view_as< TFCond >(42), 4.0); 

  TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Primary);
  Format(attribs, sizeof(attribs), "2 ; 1.5 ; 6 ; 0.1 ; 411 ; 150.0 ; 413 ; 1.0 ; 37 ; 0.0 ; 280 ; 17 ; 477 ; 1.0 ; 467 ; 1.0 ; 181 ; 2.0 ; 252 ; 0.7");
  iWeapon = boss.CallFunction("CreateWeapon", 19, "tf_weapon_grenadelauncher", 100, TFQual_Collectors, attribs);
  if (iWeapon > MaxClients)
  {
    SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
    SetEntProp(iWeapon, Prop_Send, "m_iClip1", 50);
    TF2_SetAmmo(iClient, TF_AMMO_PRIMARY, 0);
  }

  /*
  Grenade Launchere attributes:
  2: damage bonus 
  6: fire rate bonus 
  411: projectile spread angle penalty
  413: auto fires full clip
  37: hidden primary max ammo bonus 
  280: override projectile type
  477: cannonball push back 
  467: grenade not explode on impact 
  181: no self blast dmg 
  252: damage force reduction 
  */
}

public void Bunny_GetModel(SaxtonHaleBase boss, char[] sModel, int length)
{
  strcopy(sModel, length, BUNNY_MODEL);
}

static const char BunnyMatsV3[][] = {
  "materials/models/player/new_saxton_hale/easter_demo_v3/demoman_head_blue_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/demoman_head_blue_zombie_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/demoman_head_red_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/demoman_head_red_zombie_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_blue_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_blue_zombie_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_normal.vtf",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_red_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_red_zombie_invun.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_zombie.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit_zombie.vtf",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit.vmt",
  "materials/models/player/new_saxton_hale/easter_demo_v3/easter_rabbit.vtf",

  "materials/models/props_easteregg/c_easteregg.vmt",
  "materials/models/props_easteregg/c_easteregg.vtf",
  "materials/models/props_easteregg/c_easteregg_gold.vmt"
};

public void Bunny_Precache(SaxtonHaleBase boss)
{
  PrepareModel(BUNNY_MODEL);
  PrepareModel(BUNNY_EGG);
  DownloadMaterialList(BunnyMatsV3, sizeof(BunnyMatsV3));
  
  for (int i = 0; i < sizeof(g_strBunnyRoundStart); i++) PrecacheSound(g_strBunnyRoundStart[i]);
  for (int i = 0; i < sizeof(g_strBunnyWin); i++) PrecacheSound(g_strBunnyWin[i]);
  for (int i = 0; i < sizeof(g_strBunnyLose); i++) PrecacheSound(g_strBunnyLose[i]);
  for (int i = 0; i < sizeof(g_strBunnyRage); i++) PrecacheSound(g_strBunnyRage[i]);
  for (int i = 0; i < sizeof(g_strBunnyJump); i++) PrecacheSound(g_strBunnyJump[i]);
  for (int i = 0; i < sizeof(g_strBunnyKill); i++) PrecacheSound(g_strBunnyKill[i]);
  for (int i = 0; i < sizeof(g_strBunnyLastMan); i++) PrecacheSound(g_strBunnyLastMan[i]);
  for (int i = 0; i < sizeof(g_strBunnyBackStabbed); i++) PrecacheSound(g_strBunnyBackStabbed[i]);
}
