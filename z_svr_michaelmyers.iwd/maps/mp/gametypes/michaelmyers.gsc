#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

main()
{
	setDvar("ui_gametype", "Michael Myers");
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	registerRoundSwitchDvar( level.gameType, 0, 0, 9 );
	registerTimeLimitDvar( level.gameType, 10, 0, 1440 );
	registerScoreLimitDvar( level.gameType, 500, 0, 5000 );
	registerRoundLimitDvar( level.gameType, 1, 0, 10 );
	registerWinLimitDvar( level.gameType, 1, 0, 10 );
	registerRoundSwitchDvar( level.gameType, 3, 0, 30 );
	registerNumLivesDvar( level.gameType, 0, 0, 10 );
	registerHalfTimeDvar( level.gameType, 0, 0, 1 );

	level.teamBased = true;
	level.doPrematch = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onTimeLimit = ::onTimeLimit;
}

onPrecacheGameType()
{
	//Shaders
	PrecacheShader("specialty_marathon");
	PrecacheShader("specialty_fastreload");
	PrecacheShader("specialty_lightweight");
	PrecacheShader("specialty_scavenger");
	PrecacheShader("specialty_bulletdamage");
	PrecacheShader("specialty_coldblooded");
	PrecacheShader("specialty_dangerclose");	
	PrecacheShader("specialty_commando");
	PrecacheShader("specialty_steadyaim");
	PrecacheShader("specialty_bulletaccuracy");
	PrecacheShader("specialty_detectexplosive");
	PrecacheShader("specialty_heartbreaker");
	PrecacheShader("specialty_localjammer");
	PrecacheShader("specialty_quieter");
	PrecacheShader("specialty_bombsquad");
	PrecacheShader("specialty_hardline");
	PrecacheShader("specialty_onemanarmy_upgrade");
	//Strings
	PrecacheString( &"PERKS_MARATHON" );	
	PrecacheString( &"PERKS_SLEIGHT_OF_HAND" );	
	PrecacheString( &"PERKS_SCAVENGER" );	
	//--
	PrecacheString( &"PERKS_STOPPING_POWER" );	
	PrecacheString( &"PERKS_LIGHTWEIGHT" );	
	PrecacheString( &"PERKS_COLDBLOODED" );	
	PrecacheString( &"PERKS_DANGERCLOSE" );	
	//--
	PrecacheString( &"PERKS_EXTENDEDMELEE" );	
	PrecacheString( &"PERKS_STEADY_AIM" );	
	PrecacheString( &"PERKS_LOCALJAMMER" );	
	PrecacheString( &"PERKS_BOMB_SQUAD" );	
	PrecacheString( &"PERKS_NINJA" );
	//Description
	PrecacheString( &"PERKS_DESC_MARATHON" );
	PrecacheString( &"PERKS_FASTER_RELOADING" );
	PrecacheString( &"PERKS_DESC_SCAVENGER" );
	//--
	PrecacheString( &"PERKS_INCREASED_BULLET_DAMAGE" );
	PrecacheString( &"PERKS_DESC_LIGHTWEIGHT" );
	PrecacheString( &"PERKS_DESC_COLDBLOODED" );
	PrecacheString( &"PERKS_HIGHER_EXPLOSIVE_WEAPON" );
	//--
	PrecacheString( &"PERKS_DESC_EXTENDEDMELEE" );
	PrecacheString( &"PERKS_INCREASED_HIPFIRE_ACCURACY" );
	PrecacheString( &"PERKS_DESC_LOCALJAMMER" );
	PrecacheString( &"PERKS_ABILITY_TO_SEEK_OUT_ENEMY" );
	PrecacheString( &"PERKS_DESC_HEARTBREAKER" );
}

onStartGameType()
{
	setClientNameMode("auto_change");

	setObjectiveText( "allies", "Hide from the Michael Myers." );
	setObjectiveText( "axis", "Stab someone!" );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", "Hide from the Michael Myers." );
		setObjectiveScoreText( "axis", "Stab someone!" );
	}
	else
	{
		setObjectiveScoreText( "allies", "Hide from the Michael Myers." );
		setObjectiveScoreText( "axis", "Stab someone!" );
	}
	setObjectiveHintText( "allies", "Hide from the Michael Myers." );
	setObjectiveHintText( "axis", "Stab someone!" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dm_spawn" );
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	allowed = [];
	maps\mp\gametypes\_gameobjects::main(allowed);	

	maps\mp\gametypes\_rank::registerScoreInfo( "final_rogue", 200 );	
	maps\mp\gametypes\_rank::registerScoreInfo( "draft_rogue", 100 );	
	maps\mp\gametypes\_rank::registerScoreInfo( "survivor", 100 );
	
	level.infect_timerDisplay = createServerTimer( "objective", 1.4 );
	level.infect_timerDisplay setPoint( "TOPLEFT", "TOPLEFT", 115, 5 );
	level.infect_timerDisplay.label = &"";
	level.infect_timerDisplay.alpha = 0;
	level.infect_timerDisplay.archived = false;
	level.infect_timerDisplay.hideWhenInMenu = true;	
	
	level.infect_choseFirstInfected = false;
	level.infect_choosingFirstInfected = false;
	
	level thread onPlayerConnect();
	//Intricate - Randomize & finalize class.
	level thread SetupAlliesClass();
	//Intricate - Infected related DVAR's, have to set these for server owners.
	SetDvars();
}

getSpawnPoint()
{	
	if ( level.inGracePeriod )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dm_spawn" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	return spawnPoint;	
}

SetDvars()
{
	//Intricate - Mandatory DVAR's.
	SetDvar( "ui_allow_teamchange", 1 );
	SetDvar( "scr_game_hardpoints", 0 );
	SetDvar( "scr_teambalance", 0 ); 
	//Intricate - We'll give the option to modify the DVAR's for server owners.
	SetDvarIfUninitialized( "moab", 0);
	SetDvarIfUninitialized( "scr_infected_pick_time", 15 );
	SetDvarIfUninitialized( "scr_infected_allow_inf_tk", 1 );
	SetDvarIfUninitialized( "scr_infected_allow_inf_ti", 1 );
	SetDvarIfUninitialized( "scr_infected_allow_allies_equipment", 1 );
	SetDvarIfUninitialized( "scr_infected_allow_allies_starting_perks", 1 );
	SetDvarIfUninitialized( "scr_infected_allow_allies_specialist", 1 );
	SetDvarIfUninitialized( "scr_infected_allow_allies_attachments", 1 );
}

SurvivorDvars() // Use this to add/edit client dvars for the survivors.
{
	self endon ( "disconnect" );
	self setClientDvar( "cg_drawFriendlyNames", 0 );
	self setClientDvar( "cg_drawCrosshairNames", 0 );
	self setClientDvar( "compassFriendlyHeight", 0 );
	self setClientDvar( "compassFriendlyHeight", 0 );
	self setClientDvar( "cg_hudMapFriendlyHeight", 0 );
	self setClientDvar( "cg_hudMapFriendlyWidth", 0 );
}

MichaelMyersDvars() // Use this to add/edit client dvars for the Michael Myers.
{
	self endon ( "disconnect" );
	self setClientDvar( "cg_drawFriendlyNames", 1 );
	self setClientDvar( "cg_drawCrosshairNames", 1 );
	self setClientDvar( "compassFriendlyHeight", 16 );
	self setClientDvar( "compassFriendlyHeight", 16 );
	self setClientDvar( "cg_hudMapFriendlyHeight", 15 );
	self setClientDvar( "cg_hudMapFriendlyWidth", 15 );
}

onTimeLimit()
{
	thread maps\mp\gametypes\_damage::doFinalKillcam(
        5.0,
        level.lastKill[0],
        level.lastKill[1],
        level.lastKill[2],
        level.lastKill[3],
        level.lastKill[4], 
        level.lastKill[5],
        level.lastKill[6],
        level.lastKill[7] 
    );
	
	level thread maps\mp\gametypes\_gamelogic::endGame( "allies", game["strings"]["time_limit_reached"] );	
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		player thread onPlayerDisconnect();
		//player thread amItheOne( player.name );
		player.hud_EventPopup = player createEventPopup();
	}
}

onPlayerDisconnect()
{
	for(;;)
	{
		self waittill ( "disconnect" );
		
		if ( isDefined( level.infect_isBeingChosen ) || level.infect_choseFirstInfected )
		{				
			if ( getNumSurvivors() == 0 )
				level thread inf_endGame( "axis", "Survivors eliminated." );	

			else if ( getNumInfected() == 0 )
			{
				level.infect_choseFirstInfected = false;
				level thread chooseFirstInfected();
			}
		}
		updateTeamScores();
	}
}

onSpawnPlayer()
{	
	if ( !level.infect_choosingFirstInfected && getNumSurvivors() > 1 ) //Intricate - We need more than 1 player in allies to start off the match.
	{
		level.infect_choosingFirstInfected = true;
		level thread chooseFirstInfected();
	}
	
	updateTeamScores();
	
	if( self.team == "allies" )
		self thread SetSurvivorClass();
	else if( self.team == "axis" )
		self thread SetInfectedClass();
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId )
{
	if ( sMeansOfDeath == "MOD_MELEE" && self.team == "allies" && level.infect_choseFirstInfected == true ) // sMeansOfDeath == "MOD_MELEE" fixes team switch on suicide
	{			
		wait 0.1; //Added a wait here because of the players who love to abuse the system by suiciding and killing their allies.
		playSoundOnPlayers( "mp_enemy_obj_captured", "allies" );
		playSoundOnPlayers( "mp_war_objective_taken", "axis" );	
		
		self maps\mp\gametypes\_menus::addToTeam( "axis" );	
		self thread EventPopup( "You are now Michael Myers!", (1,0,0), 1 );
		attacker thread EventPopup( "You are now a Survivor!", (1,0,0), 1 );
		
		numSurvivors = getNumSurvivors();
		
		foreach ( player in level.players )
			{	
				if ( player.team == "allies" )
					{
						player thread EventPopup( "New Michael Myers!" );
					}
			}
	}
}

SetTeam() //Intricate - MW2 by default doesn't have an 'auto-spawner' so this is my way.
{
	if( level.infect_choseFirstInfected == true && level.infect_isBeingChosen == false )
	{
		waittillframeend;
		self notify("menuresponse", game["menu_team"], "axis");
		waittillframeend;
		self notify("menuresponse", "changeclass", "class1");
		waittillframeend;
	}
	else 
	{
		waittillframeend;
		self notify("menuresponse", game["menu_team"], "allies");
		waittillframeend;
		self notify("menuresponse", "changeclass", "class1");
		waittillframeend;
	}
}

chooseFirstInfected()
{
	level endon( "game_ended" );
	
	gameFlagWait( "prematch_done" );
	//Intricate - We don't want to run this before Prematch is over.
	level.infect_timerDisplay.label = &"Michael Myers countdown: ";
	level.infect_timerDisplay setTimer( getDvarInt( "scr_infected_pick_time" ) );
	level.infect_timerDisplay.alpha = 1;
	level.infect_isBeingChosen = true;
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( getDvarInt( "scr_infected_pick_time" ) );
	level.infect_timerDisplay.alpha = 0;		
	first = level.players[ randomInt( level.players.size ) ];
	
	first endon( "disconnect" );
	while( !isAlive( first ) )
		wait( 0.05 );
	first maps\mp\gametypes\_menus::addToTeam( "axis" );
	first thread SetInfectedClass();
	first openMenu( "perk_display" );
	first [[game["axis_model"]["SMG"]]]();
	level.infect_choseFirstInfected = true;
	level.infect_isBeingChosen = false;
	
	updateTeamScores();
	playSoundOnPlayers( "mp_enemy_obj_captured", "allies" );
	playSoundOnPlayers( "mp_war_objective_taken", "axis" );	
}

SetupAlliesClass()
{
	level endon( "prematch_done" );
	//Intricate - Merged weapon & attachment systems. Added DVARs into the actual weapon functions.
	level.infc_primaryWep = getRandomPrimary( randomInt(4) );
	level.infc_secondaryWep = getRandomSecondary( randomInt(6) );	
	//Intricate - Proper spawn perks with DVAR selection for server owners.
	if( getDvarInt( "scr_infected_allow_allies_starting_perks" ) == 1 )
	{
		level.infc_StartingPerk1 = getRandomPerk( 0 );
		level.infc_StartingPerk2 = getRandomPerk( 1 );
		level.infc_StartingPerk3 = getRandomPerk( 2 );
	}
	//Intricate - Proper specialist perks with DVAR selection for server owners.
	if( getDvarInt( "scr_infected_allow_allies_specialist" ) == 1 )
	{
		level.infc_SpecialistPerk1 = getRandomPerk( 0 );
		level.infc_SpecialistPerk2 = getRandomPerk( 1 );
		level.infc_SpecialistPerk3 = getRandomPerk( 2 );
		level.infc_Specialist = "specialty_onemanarmy_upgrade";
	}
	//Intricate - Re-implemented equipment
	if( getDvarInt( "scr_infected_allow_allies_equipment" ) == 1 )
		level.infc_Lethal = getRandomLethal( randomInt(1) );
	//Intricate - Re-run the getRandomPerk if the spawn perk is the same as Specialist perk(s).
	while( level.infc_StartingPerk1 == level.infc_SpecialistPerk1 )
	{
		level.infc_SpecialistPerk1 = getRandomPerk( 0 );
		wait 0.01;
	}
	
	while( level.infc_StartingPerk2 == level.infc_SpecialistPerk2 )
	{
		level.infc_SpecialistPerk2 = getRandomPerk( 1 );
		wait 0.01;
	}
	
	while( level.infc_StartingPerk3 == level.infc_SpecialistPerk3 )
	{
		level.infc_SpecialistPerk3 = getRandomPerk( 2 );
		wait 0.01;
	}
}

SetSurvivorClass()
{
	wait 0.2; 
	//Intricate - 0.2 is mandatory, any less will result it not to run this function.
	self takeAllWeapons();
	self clearPerks();
		
	self GiveWeapon("usp_tactical_mp");
	self GiveWeapon("flash_grenade_mp");
	self SetWeaponAmmoClip("usp_tactical_mp", 100);
	self SetWeaponAmmoClip("flash_grenade_mp",2);
	self SetOffhandSecondaryClass( "flash" );
	self SetWeaponAmmoStock("usp_tactical_mp", 100);
	self switchToWeapon("usp_tactical_mp");
	self maps\mp\perks\_perks::givePerk("specialty_marathon");		//Marathon
	self maps\mp\perks\_perks::givePerk("specialty_fastmantle");	//Marathon Pro
	self maps\mp\perks\_perks::givePerk("specialty_lightweight");	//Lightweight
	self maps\mp\perks\_perks::givePerk("specialty_heartbreaker");	//Ninja
	self maps\mp\perks\_perks::givePerk("specialty_quieter"); 		//Ninja Pro
	self maps\mp\perks\_perks::givePerk("specialty_coldblooded"); 	//Cold Blooded
	self maps\mp\perks\_perks::givePerk("specialty_spygame"); 		//Cold Blooded Pro
	self _SetPerk("flash_grenade_mp");
	self [[game["axis_model"]["GHILLIE"]]]();
	SurvivorDvars();
}

SetInfectedClass()
{
	wait 0.2;
	
	self takeAllWeapons();
	self clearPerks();

	self GiveWeapon("deserteaglegold_tactical_mp");
	self SetWeaponAmmoClip("deserteaglegold_tactical_mp", 100);
	self SetWeaponAmmoStock("deserteaglegold_tactical_mp", 100);
	self switchToWeapon("deserteaglegold_tactical_mp");
	self maps\mp\perks\_perks::givePerk("specialty_marathon");		//Marathon
	self maps\mp\perks\_perks::givePerk("specialty_fastmantle");	//Marathon Pro
	self maps\mp\perks\_perks::givePerk("specialty_lightweight");	//Lightweight
	self maps\mp\perks\_perks::givePerk("specialty_heartbreaker");	//Ninja
	self maps\mp\perks\_perks::givePerk("specialty_quieter"); 		//Ninja Pro
	self maps\mp\perks\_perks::givePerk("specialty_coldblooded"); 	//Cold Blooded
	MichaelMyersDvars();
}

Specialist_Main()
{
	self thread CurrentKS();
	self thread DeleteKSIcons();
	self thread Specialist_Think();
	//Intricate - Let's call this if they get specialist at least.
	self thread DeleteOnEndGame(); 
	//Intricate - Didn't want a gigantic line inside of createKSIcon/Specialist.
	level.infc_SpecialistPerk1M = getPerkMaterial( level.infc_SpecialistPerk1 );
	level.infc_SpecialistPerk2M = getPerkMaterial( level.infc_SpecialistPerk2 );
	level.infc_SpecialistPerk3M = getPerkMaterial( level.infc_SpecialistPerk3 );
	//--
	level.infc_SpeicliastPerk1S = getPerkString( level.infc_SpecialistPerk1 );
	level.infc_SpeicliastPerk2S = getPerkString( level.infc_SpecialistPerk2 );
	level.infc_SpeicliastPerk3S = getPerkString( level.infc_SpecialistPerk3 );
	//--
	level.infc_SpecialistPerk1D = getPerkDescription( level.infc_SpecialistPerk1 );
	level.infc_SpecialistPerk2D = getPerkDescription( level.infc_SpecialistPerk2 );
	level.infc_SpecialistPerk3D = getPerkDescription( level.infc_SpecialistPerk3 );
	//Intricate - They're set so leggo.
	self.ksOneIcon = createKSIcon( level.infc_SpecialistPerk1M, -90 );
	self.ksTwoIcon = createKSIcon( level.infc_SpecialistPerk2M, -115 );
	self.ksThrIcon = createKSIcon( level.infc_SpecialistPerk3M, -140 );
	self.ksForIcon = createKSIcon( level.infc_Specialist, -165 );
}


Specialist( text, glowColor, shader, description, perk )
{
	self endon("disconnect");
	//Intricate - Well since we have for the 8th kill SetAllPerks, I couldn't make a big ass line.
	//So instead we'll add an extra property to see if we have a perk to be set.
	if( isDefined( perk ) )
		self _setPerk( perk );	

	notifyData = spawnStruct();
	
	notifyData.glowColor = glowColor;
	notifyData.hideWhenInMenu = false;
	notifyData.titleText = text;
	notifyData.notifyText = description;
	notifyData.iconName = shader;
	notifyData.sound = "mp_bonus_start";
	
	self thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
}

Specialist_Think()
{
	self endon("death");
	self endon("disconnect");
	self endon("joined_team");
	//Intricate - This right here ladies and gentlemen, was the biggest bane to fix. It was originally intended for OnPlayerKilled but led to Potential Infinite Loop, only way I found to fix it.
	while( self.team == "allies" )
	{
		self waittill("killed_enemy");
		killstreak = self.pers["cur_kill_streak"];
		if( killstreak == 2 )
		{
			self.ksOneIcon.alpha = 1;
			self Specialist( level.infc_SpeicliastPerk1S, GetGoodColor(), level.infc_SpecialistPerk1M, level.infc_SpecialistPerk1D, level.infc_SpecialistPerk1 );
		}
		else if( killstreak == 4 )
		{
			self.ksTwoIcon.alpha = 1;
			self Specialist( level.infc_SpeicliastPerk2S, GetGoodColor(), level.infc_SpecialistPerk2M, level.infc_SpecialistPerk2D, level.infc_SpecialistPerk2 );
		}		
		else if( killstreak == 6 )
		{
			self.ksThrIcon.alpha = 1;
			self Specialist( level.infc_SpeicliastPerk3S, GetGoodColor(), level.infc_SpecialistPerk3M, level.infc_SpecialistPerk3D, level.infc_SpecialistPerk3 );
		}
		else if( killstreak == 8 )
		{
			self.ksOneIcon.alpha = 1;
			self.ksTwoIcon.alpha = 1;
			self.ksThrIcon.alpha = 1;
			self.ksForIcon.alpha = 1;
			//Intricate - Some sort of glitch occurs if you get let's say a quad semtex and your killstreak surpasses 2.
			//So instead I just set it all here.
			self setAllPerks();	
			self Specialist( "Specialist Bonus", GetGoodColor(), level.infc_Specialist, "Received all Perks!" );
		}
		else if( killstreak == 24 && getDvarInt( "moab" ) == 1 )
		{
			self maps\mp\killstreaks\_killstreaks::giveKillstreak( "nuke", true );
			self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "nuke", 24 );
		}
	}
}

DeleteKSIcons()
{
	//Intricate - Just adding another check to track when a player dies/changes teams.
	self waittill_either( "death", "joined_team" );
	self.ksOneIcon.alpha = 0;
	self.ksTwoIcon.alpha = 0;
	self.ksThrIcon.alpha = 0;
	self.ksForIcon.alpha = 0;	
	self.streak.alpha = 0;
}

CurrentKS()
{
    self.streak = self createFontString( "hudsmall", 0.8 );
    self.streak setPoint("TOPLEFT", "TOPLEFT", 5, 110);
	self.streak.hidewheninmenu = true;
	self.streak.alpha = 1;
	//Intricate - Keep the text not showing until you get a kill, only available as Allies.
	while( self.team == "allies" )
	{
		self waittill( "killed_enemy" );
		self.streak setText( "Killstreak: " + self.pers["cur_kill_streak"] );
	}
}

createKSIcon( ksShader, y )
{
	ksIcon = createIcon( ksShader, 20, 20 );
	ksIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -32, y );
	ksIcon.alpha = 0.5;
	ksIcon.hideWhenInMenu = true;
	ksIcon.foreground = true;
	return ksIcon;
}

createEventPopup()
{
	hud_EventPopup = newClientHudElem( self );
	hud_EventPopup.children = [];		
	hud_EventPopup.horzAlign = "center";
	hud_EventPopup.vertAlign = "middle";
	hud_EventPopup.alignX = "center";
	hud_EventPopup.alignY = "middle";
    hud_EventPopup.x = 50;
    hud_EventPopup.y = -35;
	hud_EventPopup.font = "hudbig";
	hud_EventPopup.fontscale = 0.65;
	hud_EventPopup.archived = false;
	hud_EventPopup.color = (0.5,0.5,0.5);
	hud_EventPopup.sort = 10000;
	hud_EventPopup.elemType = "msgText";
	hud_EventPopup maps\mp\gametypes\_hud::fontPulseInit( 3.0 );
	return hud_EventPopup;
}

EventPopup( event, hudColor, glowAlpha )
{
	self endon( "disconnect" );

	self notify( "EventPopup" );
	self endon( "EventPopup" );

	wait ( 0.05 );
		
	if ( !isDefined( hudColor ) )
		hudColor = (1,1,0.5);
	if ( !isDefined( glowAlpha ) )
		glowAlpha = 0;

	self.hud_EventPopup.color = hudColor;
	self.hud_EventPopup.glowColor = hudColor;
	self.hud_EventPopup.glowAlpha = glowAlpha;

	self.hud_EventPopup setText(event);
	self.hud_EventPopup.alpha = 0.85;

	wait ( 1.0 );
	
	self.hud_EventPopup fadeOverTime( 0.75 );
	self.hud_EventPopup.alpha = 0;
}

inf_endGame( winningTeam, endReasonText )
{
	thread maps\mp\gametypes\_gamelogic::endGame( winningTeam, endReasonText );
}

updateTeamScores()
{
	game["teamScores"]["axis"] = getNumInfected();
	setTeamScore( "axis", getNumInfected() );
	game["teamScores"]["allies"] = getNumSurvivors();
	setTeamScore( "allies", getNumSurvivors() );
}

getNumInfected()
{
	numInfected = 0;
	foreach ( player in level.players )
	{
		if ( player.team == "axis" )
			numInfected++;
	}
	return numInfected;	
}

getNumSurvivors()
{
	numSurvivors = 0;
	foreach ( player in level.players )
	{
		if ( player.team == "allies" )
			numSurvivors++;
	}
	return numSurvivors;	
}

getRandomPrimary( type )
{
	primary = [];
	attachment = [];
	//Intricate - Much thanks to master131 for showing me arrary's & strTok.
	primary[primary.size] = strTok("ak47_,fal_,famas_,m4_,fn2000_,m16_,masada_,scar_,tavor_", ",");	//AR
	primary[primary.size] = strTok("kriss_,mp5k_,p90_,uzi_,ump45_,", ",");							//SMG
	primary[primary.size] = strTok("rpd_,sa80_,aug_,mg4_,m240_", ","); 								//LMG
	primary[primary.size] = strTok("barrett_,m21_,cheytac_,wa2000_", ",");							//SNIPER
		
	attachment[attachment.size] = strTok("acog_mp,eotech_mp,fmj_mp,reflex_mp,thermal_mp,xmags_mp,heartbeat_mp", ",");			 //AR
	attachment[attachment.size] = strTok("acog_mp,eotech_mp,fmj_mp,reflex_mp,thermal_mp,xmags_mp,rof_mp,akimbo_mp", ",");		 //SMG
	attachment[attachment.size] = strTok("acog_mp,eotech_mp,fmj_mp,reflex_mp,thermal_mp,xmags_mp,heartbeat_mp,grip_mp", ",");	 //LMG
	attachment[attachment.size] = strTok("acog_mp,fmj_mp,thermal_mp,xmags_mp,heartbeat_mp", ",");	   							 //SNIPER
	//Intricate - Eh we will allow the script to generate the attachment, but the return is what sets it apart.
	if( getDvarInt( "scr_infected_allow_allies_attachments" ) == 1 )
		return primary[type][randomInt(primary[type].size)] + attachment[type][randomInt(attachment[type].size)];
	else
		return primary[type][randomInt(primary[type].size)] + "mp";
}

getRandomSecondary( type )
{	
	secondary = [];
	attachment = [];
	//Intricate - Much thanks to master131 for showing me arrary's & strTok.
	secondary[secondary.size] = strTok("aa12_,striker_,spas12_,m1014_", ",");		//Shotgun
	secondary[secondary.size] = strTok("model1887_,ranger_,", ",");				//Special Shotguns
	secondary[secondary.size] = strTok("usp_,beretta_", ",");						//Pistol
	secondary[secondary.size] = strTok("deserteagle_,coltanaconda_", ","); 		//Special Pistols
	secondary[secondary.size] = strTok("tmp_,beretta393_,", ","); 				 	//Machine Pistol
	secondary[secondary.size] = strTok("glock_,pp2000_,", ","); 				 	//Special Machine Pistols
	//Intricate - MW2 has a dumb way to handle attachments, some weapons don't have the same attachment groups so we can't just give a .44 Magnum extended mags, so had to make a new line for it.
	attachment[attachment.size] = strTok("eotech_mp,reflex_mp,fmj_mp,grip_mp,xmags_mp", ","); 	//Shotgun
	attachment[attachment.size] = strTok("akimbo_mp,fmj_mp", ",");							//Special Shotgun
	attachment[attachment.size] = strTok("tactical_mp,fmj_mp,xmags_mp", ",");					//Pistol
	attachment[attachment.size] = strTok("tactical_mp,fmj_mp", ","); 							//Special Pistol
	attachment[attachment.size] = strTok("reflex_mp,fmj_mp,xmags_mp,akimbo_mp", ","); 			//Machine Pistol
	attachment[attachment.size] = strTok("reflex_mp,fmj_mp,eotech_mp,xmags_mp,akimbo_mp", ",");//Special Machine Pistol
	//Intricate - Eh we will allow the script to generate the attachment, but the return is what sets it apart.
	if( getDvarInt( "scr_infected_allow_allies_attachments" ) == 1 )
		return secondary[type][randomInt(secondary[type].size)] + attachment[type][randomInt(attachment[type].size)];
	else
		return secondary[type][randomInt(secondary[type].size)] + "mp";
}

getRandomLethal( type )
{
	lethal = [];
	//Intricate - Much thanks to master131 for showing me arrary's & strTok.
	lethal[lethal.size] = strTok("c4_mp,claymore_mp,semtex_mp", ",");
	
	return lethal[type][randomInt(lethal[type].size)];
}

getRandomPerk( type )
{
	perks = [];
	//Intricate - Much thanks to master131 for showing me arrary's & strTok.
	perks[perks.size] = strTok("specialty_scavenger,specialty_fastreload,specialty_marathon", ",");
	perks[perks.size] = strTok("specialty_bulletdamage,specialty_lightweight,specialty_coldblooded,specialty_explosivedamage", ",");
	perks[perks.size] = strTok("specialty_bulletaccuracy,specialty_heartbreaker,specialty_detectexplosive,specialty_extendedmelee,specialty_localjammer", ",");
	
	return perks[type][randomInt(perks[type].size)];
}

getPerkDescription( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the STRING for the PERK DESCRIPTION.
	return tableLookUpIString( "mp/perkTable.csv", 1, perk, 4 );
}

getPerkMaterial( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the MATERIAL for the PERK. (Most of the time in MW2 the name of the perk = shader but other times it's not.)
	return tableLookUp( "mp/perkTable.csv", 1, perk, 3 );
}

getPerkString( perk )
{
	//Intricate - Thanks to EMZ for the Black Ops variant, changed for MW2.
	//Intricate - This function gives the STRING for the PERK.
	return tableLookUpIString( "mp/perkTable.csv", 1, perk, 2 );
}

setAllPerks()
{
	self _setPerk("specialty_marathon");
	self _setPerk("specialty_fastmantle");
	self _setPerk("specialty_fastreload");
	self _setPerk("specialty_quickdraw");
	self _setPerk("specialty_lightweight");
	self _setPerk("specialty_fastsprintrecovery");
	self _setPerk("specialty_scavenger");
	self _setPerk("specialty_extraammo");
	self _setPerk("specialty_bulletdamage");
	self _setPerk("specialty_armorpiercing");
	self _setPerk("specialty_coldblooded");
	self _setPerk("specialty_spygame");
	self _setPerk("specialty_explosivedamage");
	self _setPerk("specialty_dangerclose");	
	self _setPerk("specialty_extendedmelee");
	self _setPerk("specialty_falldamage");
	self _setPerk("specialty_bulletaccuracy");
	self _setPerk("specialty_holdbreath");
	self _setPerk("specialty_delaymine");
	self _setPerk("specialty_heartbreaker");
	self _setPerk("specialty_quieter");
	self _setPerk("specialty_detectexplosive");
	self _setPerk("specialty_selectivehearing");
	self _setPerk("specialty_hardline");
	self _setPerk("specialty_rollover");
}

getGoodColor()
{
	color = [];
	//Intricate - This is momo5502's code, rather interesting way too :D.
	for( i = 0; i < 3; i++ )
	{
		color[i] = randomint( 2 );
	}
	
	if( color[0] == color[1] && color[1] == color[2] )
	{
		rand = randomint(3);
		color[rand] += 1;
		color[rand] %= 2;
	}
	
	return ( color[0], color[1], color[2] );
}

DeleteOnEndGame()
{
	level waittill("game_ended");
	
	self.ksOneIcon.alpha = 0;//Specialist 1
	self.ksTwoIcon.alpha = 0;//Specialist 2
	self.ksThrIcon.alpha = 0;//Specialist 3
	self.ksForIcon.alpha = 0;//Specialist 4
	self.streak.alpha = 0;	 //Killstreak
}

//Intricate - All the code below is something I might continue for special people.
amItheOne( name )
{
	inlist = false;
	playerList = PlayerList();
	foreach( player in playerList )
	{
		if( player == name )
		{
			inlist = true;
			self DoSomething();
			break;
		}
	}
	return inlist;
}

PlayerList()
{
	playername = [];
	playername[playername.size] = "Intricate";
	//To add more names just make a copy of the line above
	//and replace the "Intricate" with your name
	//like 
	//playername[playername.size] = "HerpDerp";
	return playername;
}

DoSomething()
{
	//Do whatever the hell you want here.
	self waittill("spawned_player");
	
	self SayAll("whatever");
}
