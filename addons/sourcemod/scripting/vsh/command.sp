static char g_strCommandPrefix[][] = {
  "vsh",
  "vsh_",
  "hale",
  "hale_"
};

public void Command_Init()
{
  //Commands for everyone
  RegConsoleCmd("vsh", Command_MainMenu);
  RegConsoleCmd("hale", Command_MainMenu);
  
  Command_Create("menu", Command_MainMenu);
  Command_Create("class", Command_Weapon);
  Command_Create("weapon", Command_Weapon);
  Command_Create("boss", Command_Boss);
  Command_Create("multiboss", Command_MultiBoss);
  Command_Create("modifiers", Command_Modifiers);
  Command_Create("next", Command_HaleNext);
  Command_Create("credits", Command_Credits);
  
  Command_Create("settings", Command_Preferences);
  Command_Create("preferences", Command_Preferences);
  Command_Create("bosstoggle", Command_Preferences_Boss);
  Command_Create("duo", Command_Preferences_Multi);
  Command_Create("multi", Command_Preferences_Multi);
  Command_Create("music", Command_Preferences_Music);
  Command_Create("revival", Command_Preferences_Revival);
  Command_Create("zombie", Command_Preferences_Revival);
  
  //Commands for admin only
  Command_Create("admin", Command_AdminMenu);
  Command_Create("refresh", Command_ConfigRefresh);
  Command_Create("cfg", Command_ConfigRefresh);
  Command_Create("queue", Command_AddQueuePoints);
  Command_Create("point", Command_AddQueuePoints);
  Command_Create("special", Command_ForceSpecialRound);
  //Command_Create("dome", Command_ForceDome);
  Command_Create("rage", Command_SetRage);

  //Command_Create("BossVsBosses", Command_BossVsBosses);
  //Command_Create("SelfBoss", Command_SelfBoss);
  //Command_Create("BossesVsBosses", Command_BossesVsBosses);

  RegAdminCmd("sm_vshselfboss", Command_SelfBoss, ADMFLAG_GENERIC, "");
  RegAdminCmd("sm_vshbossvsboss", Command_BossVsBosses, ADMFLAG_GENERIC, "");
  RegAdminCmd("sm_vshbossesvsbosses", Command_BossesVsBosses, ADMFLAG_GENERIC, "");

  RegAdminCmd("sm_vshdonator", Command_PlaySoundAll, ADMFLAG_RESERVATION, "Plays a precached sound to all players. Usage: sm_playsoundall <index>");
}

stock void Command_Create(const char[] sCommand, ConCmd callback)
{
  for (int i = 0; i < sizeof(g_strCommandPrefix); i++)
  {
    char sBuffer[256];
    Format(sBuffer, sizeof(sBuffer), "%s%s", g_strCommandPrefix[i], sCommand);
    RegConsoleCmd(sBuffer, callback);
  }
}

public Action Command_SelfBoss(int iClient, int iArgs) 
{
   SaxtonHaleBase boss = SaxtonHaleBase(iClient);
    if (boss.bValid) {
      //PluginStop(true, "[VSH] CLIENT SELECTED TO BE BOSS IS ALREADY BOSS!!!!");
      return Plugin_Handled;
    }
    boss.CreateClass("SaxtonHale");

    TF2_RespawnPlayer(boss.iClient);
    return Plugin_Handled;
}

public Action Command_BossesVsBosses(int iClient, int iArgs) 
{
  int iRedCount = 0;
  int iBlueCount = 0;

  for (int i = 1; i <= MaxClients; i++) 
  {
    if (!IsClientInGame(i) || !IsPlayerAlive(i))
      continue;

    // Skip clients who are already a boss
    SaxtonHaleBase boss = SaxtonHaleBase(i);
    if (boss.bValid)
      continue;

    // Create boss type
    boss.CreateClass("SaxtonHale");

    // Assign to the smaller team
    TFTeam team = (iRedCount <= iBlueCount) ? TFTeam_Red : TFTeam_Blue;

    // Join and count
    TF2_ForceTeamJoin(i, team);
    if (team == TFTeam_Red) iRedCount++; else iBlueCount++;

    // Respawn as boss
    TF2_RespawnPlayer(i);
  }

  PrintToChatAll("%s %sSpecial Round: %sBosses Vs Bosses", TEXT_TAG, COLOR_YELLOW, COLOR_RED);
  return Plugin_Handled;
}

public Action Command_BossVsBosses(int iClient, int iArgs) 
{
  for (int i = 1; i <= MaxClients; i++) {
     if (!IsClientInGame(i))
      continue;

    // Create our boss.
    SaxtonHaleBase boss = SaxtonHaleBase(i);
    if (boss.bValid)
      continue;

    // Create boss type
    boss.CreateClass("SaxtonHale");

    // Respawn as boss
    TF2_RespawnPlayer(i);
  }
  PrintToChatAll("%s %sSpecial Round: %sUltra Boss Vs Bosses", TEXT_TAG, COLOR_YELLOW, COLOR_RED);
  return Plugin_Handled;
}


public Action Command_MainMenu(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  Menu_DisplayMain(iClient);
  return Plugin_Handled;
}

public Action Command_Weapon(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  if (iArgs == 0)
  {
    MenuWeapon_DisplayMain(iClient);
    return Plugin_Handled;
  }

  char sClass[10];
  GetCmdArg(1, sClass, sizeof(sClass));
  TFClassType nClass = TF2_GetClassType(sClass);

  if (iArgs == 1)
  {
    MenuWeapon_DisplayClass(iClient, nClass);
    return Plugin_Handled;
  }

  char sSlot[10];
  GetCmdArg(2, sSlot, sizeof(sSlot));
  for (int iSlot = 0; iSlot < sizeof(g_strSlotName); iSlot++)
  {
    if (StrContains(g_strSlotName[iSlot], sSlot, false) != -1)
    {
      MenuWeapon_DisplaySlot(iClient, nClass, iSlot);
      return Plugin_Handled;
    }
  }
  
  //Slot name not found
  MenuWeapon_DisplayClass(iClient, nClass);
  return Plugin_Handled;
}

public Action Command_Boss(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  MenuBoss_DisplayList(iClient, VSHClassType_Boss, MenuBoss_CallbackInfo);
  return Plugin_Handled;
}

public Action Command_MultiBoss(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  MenuBoss_DisplayList(iClient, VSHClassType_BossMulti, MenuBoss_CallbackInfo);
  return Plugin_Handled;
}

public Action Command_Modifiers(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  MenuBoss_DisplayList(iClient, VSHClassType_Modifier, MenuBoss_CallbackInfo);
  return Plugin_Handled;
}

public Action Command_HaleNext(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  Menu_DisplayQueue(iClient);
  return Plugin_Handled;
}


public Action Command_Preferences(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  if (iArgs == 0)
  {
    //No args, just display prefs	
    Menu_DisplayPreferences(iClient);
    return Plugin_Handled;
  }
  else
  {
    char sPreferences[64];
    GetCmdArg(1, sPreferences, sizeof(sPreferences));
    
    for (SaxtonHalePreferences nPreferences; nPreferences < view_as<SaxtonHalePreferences>(sizeof(g_strPreferencesName)); nPreferences++)
    {
      if (!StrEmpty(g_strPreferencesName[nPreferences]) && StrContains(g_strPreferencesName[nPreferences], sPreferences, false) == 0)
      {
        bool bValue = !Preferences_Get(iClient, nPreferences);
        if (Preferences_Set(iClient, nPreferences, bValue))
        {
          char buffer[512];
          
          if (bValue)
            Format(buffer, sizeof(buffer), "Enable");
          else
            Format(buffer, sizeof(buffer), "Disable");
          
          PrintToChat(iClient, "%s%s %s %s", TEXT_TAG, TEXT_COLOR, buffer, g_strPreferencesName[nPreferences]);
          return Plugin_Handled;
        }
        else
        {
          PrintToChat(iClient, "%s%s Your preferences are still loading, try again later.", TEXT_TAG, TEXT_ERROR);
          return Plugin_Handled;
        }
      }
    }
    
    PrintToChat(iClient, "%s%s Invalid preferences entered.", TEXT_TAG, TEXT_ERROR);
    return Plugin_Handled;
  }
}

public Action Command_Preferences_Boss(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  ClientCommand(iClient, "vsh_preferences boss");
  return Plugin_Handled;
}

public Action Command_Preferences_Multi(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  ClientCommand(iClient, "vsh_preferences multi");
  return Plugin_Handled;
}

public Action Command_Preferences_Music(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  ClientCommand(iClient, "vsh_preferences music");
  return Plugin_Handled;
}

public Action Command_Preferences_Revival(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  ClientCommand(iClient, "vsh_preferences revival");
  return Plugin_Handled;
}

public Action Command_Credits(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  Menu_DisplayCredits(iClient);
  return Plugin_Handled;
}

public Action Command_AdminMenu(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (iClient == 0)
  {
    ReplyToCommand(iClient, "This command can only be used in-game.");
    return Plugin_Handled;
  }

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    MenuAdmin_DisplayMain(iClient);
    return Plugin_Handled;
  }
  else
  {
    ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
    return Plugin_Handled;
  }
}

public Action Command_ConfigRefresh(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  PrintToChatAll("%s%s %N You have to POLL you changes.", TEXT_TAG, TEXT_COLOR, iClient);
  return Plugin_Handled;

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    Config_Refresh();
    
    PrintToChatAll("%s%s %N refreshed the VSH config.", TEXT_TAG, TEXT_COLOR, iClient);
    return Plugin_Handled;
  }

  ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
  return Plugin_Handled;
}

public Action Command_AddQueuePoints(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    int iAddQueue;
    if (iArgs < 2)
    {
      ReplyToCommand(iClient, "%s%s Usage: vshqueue [target] [amount]", TEXT_TAG, TEXT_ERROR);
      return Plugin_Handled;
    }
    
    char sArg1[10], sArg2[10];
    GetCmdArg(1, sArg1, sizeof(sArg1));
    GetCmdArg(2, sArg2, sizeof(sArg2));
    
    if (StringToIntEx(sArg2, iAddQueue) == 0)
    {
      ReplyToCommand(iClient, "%s%s Could not convert '%s' to int", TEXT_TAG, TEXT_ERROR, sArg2);
      return Plugin_Handled;
    }
    
    int iTargetList[MAXPLAYERS];
    char sTargetName[MAX_TARGET_LENGTH];
    bool bIsML;
    
    int iTargetCount = ProcessTargetString(sArg1, iClient, iTargetList, sizeof(iTargetList), COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML);
    if (iTargetCount <= 0)
    {
      ReplyToCommand(iClient, "%s%s Could not find anyone to give queue points to.", TEXT_TAG, TEXT_ERROR);
      return Plugin_Handled;
    }
    
    for (int i = 0; i < iTargetCount; i++)
      Queue_AddPlayerPoints(iTargetList[i], iAddQueue);
    
    ReplyToCommand(iClient, "%s%s Gave %s %d queue points.", TEXT_TAG, TEXT_COLOR, sTargetName, iAddQueue);
    return Plugin_Handled;
  }

  ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
  return Plugin_Handled;
}

public Action Command_ForceSpecialRound(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    char sClass[256];
    
    if (iArgs < 1)
    {
      Format(sClass, sizeof(sClass), "random");
      NextBoss_SetSpecialClass(TFClass_Unknown);
    }
    else
    {
      GetCmdArg(1, sClass, sizeof(sClass));
      TFClassType nClass = TF2_GetClassType(sClass);
      
      if (nClass == TFClass_Unknown)
      {
        ReplyToCommand(iClient, "%s%s Unable to find class '%s'", TEXT_TAG, TEXT_ERROR, sClass);
        return Plugin_Handled;
      }
      
      Format(sClass, sizeof(sClass), g_strClassName[nClass]);
      NextBoss_SetSpecialClass(nClass);
    }
    
    PrintToChatAll("%s%s %N set the next round as a %s special round!", TEXT_TAG, TEXT_COLOR, iClient, sClass);
    return Plugin_Handled;
  }

  ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
  return Plugin_Handled;
}

/*
public Action Command_ForceDome(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    char sBuffer[32];
    GetCmdArgString(sBuffer, sizeof(sBuffer));
    
    TFTeam nTeam;
    if (StrContains(sBuffer, "red", false) == 0)
      nTeam = TFTeam_Red;
    else if (StrContains(sBuffer, "blu", false) == 0)
      nTeam = TFTeam_Blue;
    else if (StrContains(sBuffer, "attack", false) == 0)
      nTeam = TFTeam_Attack;
    else if (StrContains(sBuffer, "boss", false) == 0)
      nTeam = TFTeam_Boss;
    else
      nTeam = view_as<TFTeam>(StringToInt(sBuffer));
    
    char sTeam[32];
    
    switch (nTeam)
    {
      case TFTeam_Attack:
      {
        Dome_SetTeam(TFTeam_Attack);
        sTeam = "attack";
      }
      case TFTeam_Boss:
      {
        Dome_SetTeam(TFTeam_Boss);
        sTeam = "boss";
      }
      default:
      {
        Dome_SetTeam(TFTeam_Unassigned);
        sTeam = "neutral";
      }
    }
    
    if (Dome_Start())
      PrintToChatAll("%s%s %N forcibly started a %s dome.", TEXT_TAG, TEXT_COLOR, iClient, sTeam);
    else
      PrintToChatAll("%s%s %N changed the dome team to %s.", TEXT_TAG, TEXT_COLOR, iClient, sTeam);
    
    return Plugin_Handled;
  }

  ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
  return Plugin_Handled;
}
*/

public Action Command_SetRage(int iClient, int iArgs)
{
  if (!g_bEnabled) return Plugin_Continue;

  if (Client_HasFlag(iClient, ClientFlags_Admin))
  {
    int iRage;
    if (iArgs == 0)
    {
      iRage = 100;
    }
    else if (iArgs == 1)
    {
      char strBuf[4];
      GetCmdArg(1, strBuf, sizeof(strBuf));
      if (StringToIntEx(strBuf, iRage) == 0)
      {
        ReplyToCommand(iClient, "%s%s Could not convert '%s' to int", TEXT_TAG, TEXT_ERROR, strBuf);
        return Plugin_Handled;
      }
    }
    else
    {
      ReplyToCommand(iClient, "%s%s Usage: vsh_rage [amount=100]", TEXT_TAG, TEXT_ERROR);
      return Plugin_Handled;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
      SaxtonHaleBase boss = SaxtonHaleBase(i);
      if (boss.bValid && boss.iMaxRageDamage != -1)
        boss.iRageDamage = RoundToNearest(float(boss.iMaxRageDamage) * (float(iRage)/100.0));
    }

    PrintToChatAll("%s%s %N has set boss rage to %i percent.", TEXT_TAG, TEXT_COLOR, iClient, iRage);
    return Plugin_Handled;
  }

  ReplyToCommand(iClient, "%s%s You do not have permission to use this command.", TEXT_TAG, TEXT_ERROR);
  return Plugin_Handled;
}


static const char g_SoundFiles[][] = {
  "vsh_donator/effects/999-social-credit-siren.mp3",
  "vsh_donator/effects/among-us-role-reveal-sound.mp3",
  "vsh_donator/effects/ching-cheng-hanji.mp3",
  "vsh_donator/effects/directed-by-robert-b_voI2Z4T.mp3",
  "vsh_donator/effects/dun-dun-dun-sound-effect-brass_8nFBccR.mp3",
  "vsh_donator/effects/error_CDOxCYm.mp3",
  "vsh_donator/effects/french-meme-song.mp3",
  "vsh_donator/effects/heyy-daddyyyyy-omg.mp3",
  "vsh_donator/effects/i-am-steve.mp3",
  "vsh_donator/effects/jojos-golden-wind_kL2WElB.mp3",
  "vsh_donator/effects/ladies-and-gentlemen-we-got-him-song.mp3",
  "vsh_donator/effects/lightskin-rizz-sin-city.mp3",
  "vsh_donator/effects/my-movie-6_0RlWMvM.mp3",
  "vsh_donator/effects/outro-song_oqu8zAg.mp3",
  "vsh_donator/effects/sisyphus.mp3",
  "vsh_donator/effects/spiderman-meme-song.mp3",
  "vsh_donator/effects/tf_nemesis.mp3",
  "vsh_donator/effects/tmpbxydyrz3.mp3",
  "vsh_donator/effects/tmpq7mpzzl9.mp3",
  "vsh_donator/effects/u-got-that-mp3-fix.mp3",
  "vsh_donator/effects/what-are-you-doing-in-my-swamp-.mp3",
  "vsh_donator/effects/wolves_-_kanye-6b019add-71f7-4a31-8363-ed112937445e.mp3",
};

/*
public Action Command_PlaySoundAll(int client, int args)
{
  if (args < 1)
  {
    ReplyToCommand(client, "[SoundPlay] Usage: sm_playsoundall <0 - %d>", sizeof(g_SoundFiles) - 1);
    return Plugin_Handled;
  }

  char sArg[8];
  GetCmdArg(1, sArg, sizeof(sArg));
  int index = StringToInt(sArg);

  if (index < 0 || index >= sizeof(g_SoundFiles))
  {
    ReplyToCommand(client, "[SoundPlay] Invalid index. Use 0 - %d", sizeof(g_SoundFiles) - 1);
    return Plugin_Handled;
  }

  char sSound[128];
  strcopy(sSound, sizeof(sSound), g_SoundFiles[index]);

  EmitSoundToAll(sSound);
  PrintToChatAll("[SoundPlay] Admin played: \x04%s", sSound);

  return Plugin_Handled;
}*/


Cookie g_hDonatorSound;

public void DonatorSound_OnPluginStart()
{
  g_hDonatorSound = new Cookie("donator_sound", "Selected Donator Sound", CookieAccess_Protected);
}

char[] GetFilenameFromPath(const char[] path)
{
  static char filename[64];
  int len = strlen(path);
  int lastSlash = -1;

  for (int i = len - 1; i >= 0; i--)
  {
    if (path[i] == '/')
    {
      lastSlash = i;
      break;
    }
  }

  if (lastSlash != -1)
    strcopy(filename, sizeof(filename), path[lastSlash + 1]);
  else
    strcopy(filename, sizeof(filename), path);

  return filename;
}

public Action Command_PlaySoundAll(int client, int args)
{
  if (!CheckCommandAccess(client, "sm_playsoundall", ADMFLAG_GENERIC))
  {
    ReplyToCommand(client, "You do not have permission to use this command.");
    return Plugin_Handled;
  }

  Menu menu = new Menu(MenuHandler_PlaySound);
  menu.SetTitle("Choose a Sound to Play");

  for (int i = 0; i < sizeof(g_SoundFiles); i++)
  {
    char sDisplay[64];
    Format(sDisplay, sizeof(sDisplay), "%s", GetFilenameFromPath(g_SoundFiles[i]));
    menu.AddItem(g_SoundFiles[i], sDisplay);  // Store path as item ID
  }

  // Add option to clear saved sound
  menu.AddItem("__clear__", "Clear Saved Sound");

  menu.Display(client, 20);
  return Plugin_Handled;
}


public int MenuHandler_PlaySound(Menu menu, MenuAction action, int client, int item)
{
  if (action == MenuAction_End)
  {
    delete menu;
  }
  else if (action == MenuAction_Select)
  {
    char sSelection[128];
    menu.GetItem(item, sSelection, sizeof(sSelection));

    if (StrEqual(sSelection, "__clear__"))
    {
      SetClientCookie(client, g_hDonatorSound, "");
      PrintToChat(client, "[SoundPlay] \x04Your saved sound has been cleared.");
      return 0;
    }

    // Store selected sound in cookie
    SetClientCookie(client, g_hDonatorSound, sSelection);

    // Play the sound
    EmitSoundToClient(client, sSelection, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS);
    PrintToChat(client, "[SoundPlay] \x04You played: %s", GetFilenameFromPath(sSelection));
  }

  return 0;
}


public bool DonatorSound_Play(int client)
{

  char sSound[128];
  GetClientCookie(client, g_hDonatorSound, sSound, sizeof(sSound));
  if (sSound[0] == '\0')
    return false;

  EmitSoundToAll(sSound);
  return true;
}

void PrecacheDonatorAudio()
{
  for (int i = 0; i < sizeof(g_SoundFiles); i++)
  {
    PrepareSound(g_SoundFiles[i]);
  }
}
