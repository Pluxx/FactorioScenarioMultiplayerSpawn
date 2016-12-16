-- control.lua
-- Nov 2016

-- Oarc's Separated Spawn Scenario
-- 
-- I wanted to create a scenario that allows you to spawn in separate locations
-- From there, I ended up adding a bunch of other minor/major features
-- 
-- Credit:
--  RSO mod to RSO author - Orzelek - I contacted him via the forum
--  Tags - Taken from WOGs scenario
--  Event - Taken from WOGs scenario (looks like original source was 3Ra)
--  Rocket Silo - Taken from Frontier as an idea
--
-- Feel free to re-use anything you want. It would be nice to give me credit
-- if you can.
-- 
-- Follow server info on @_Oarc_


-- To keep the scenario more manageable I have done the following:
--      1. Keep all event calls in control.lua (here)
--      2. Put all config options in config.lua
--      3. Put mods into their own files where possible (RSO has multiple)


-- My Scenario Includes
require("oarc_utils")
require("config")

-- Include Mods
require("separate_spawns")
require("separate_spawns_guis")
require("rso_control")
require("frontier_silo")
require("tag")


--------------------------------------------------------------------------------
-- Rocket Launch Event Code
-- Controls the "win condition"
--------------------------------------------------------------------------------
function RocketLaunchEvent(event)
    local force = event.rocket.force
    
    if event.rocket.get_item_count("satellite") == 0 then
        for index, player in pairs(force.players) do
            player.print("You launched the rocket, but you didn't put a satellite inside.")
        end
        return
    end

    if not global.satellite_sent then
        global.satellite_sent = {}
    end

    if global.satellite_sent[force.name] then
        global.satellite_sent[force.name] = global.satellite_sent[force.name] + 1   
    else
        game.set_game_state{game_finished=true, player_won=true, can_continue=true}
        global.satellite_sent[force.name] = 1
    end
    
    for index, player in pairs(force.players) do
        if player.gui.left.rocket_score then
            player.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[force.name])
        else
            local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
            frame.add{name="rocket_count_label", type = "label", caption={"", "Satellites launched", ":"}}
            frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[force.name])}
        end
    end
end


--------------------------------------------------------------------------------
-- ALL EVENT HANLDERS ARE HERE IN ONE PLACE!
--------------------------------------------------------------------------------


----------------------------------------
-- On Init - only runs once the first 
--   time the game starts
----------------------------------------
script.on_init(function(event)
    if ENABLE_SEPARATE_SPAWNS then
        InitSpawnGlobalsAndForces()
    end

    if ENABLE_RANDOM_SILO_POSITION then
        SetRandomSiloPosition()
    else
        SetFixedSiloPosition()
    end

    if FRONTIER_ROCKET_SILO_MODE then
        ChartRocketSiloArea(game.forces[MAIN_FORCE])
    end

    -- local entityTest = game.surfaces["nauvis"].create_entity({name = "big-ship-wreck-1", position = {0, 0}, force = "neutral", direction = 0})
    -- game.surfaces["nauvis"].create_entity({name="flying-text", position={0,0}, text="Hello world", color={r=0.5,g=1,b=1}})
    -- local entityEnvTest = entityTest.get_inventory(defines.inventory.chest)
    -- entityEnvTest.insert{name="iron-plate", count=3}

end)


----------------------------------------
-- Freeplay rocket launch info
-- Slightly modified for my purposes
----------------------------------------
script.on_event(defines.events.on_rocket_launched, function(event)
    if FRONTIER_ROCKET_SILO_MODE then
        RocketLaunchEvent(event)
    end
end)


----------------------------------------
-- Chunk Generation
----------------------------------------
script.on_event(defines.events.on_chunk_generated, function(event)
    if ENABLE_UNDECORATOR then
        UndecorateOnChunkGenerate(event)
    end

    if ENABLE_RSO then
        RSO_ChunkGenerated(event)
    end

    if FRONTIER_ROCKET_SILO_MODE then
        GenerateRocketSiloChunk(event)
    end

    -- This MUST come after RSO generation!
    if ENABLE_SEPARATE_SPAWNS then
        SeparateSpawnsGenerateChunk(event)
    end
end)


----------------------------------------
-- Gui Click
----------------------------------------
script.on_event(defines.events.on_gui_click, function(event)
    if ENABLE_TAGS then
        TagGuiClick(event)
    end

    if ENABLE_SEPARATE_SPAWNS then
        WelcomeTextGuiClick(event)
        SpawnOptsGuiClick(event)
        SpawnCtrlGuiClick(event)
        SharedSpwnOptsGuiClick(event)
    end
end)


----------------------------------------
-- Player Events
----------------------------------------
script.on_event(defines.events.on_player_joined_game, function(event)
    
    PlayerJoinedMessages(event)

    if ENABLE_TAGS then
        CreateTagGui(event)
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    if ENABLE_RSO then
        RSO_PlayerCreated(event)
    end

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end

    if not ENABLE_SEPARATE_SPAWNS then
        PlayerSpawnItems(event)
    else
        SeparateSpawnsPlayerCreated(event)
    end
end)

script.on_event(defines.events.on_player_died, function(event)
    if ENABLE_GRAVESTONE_CHESTS then
        CreateGravestoneChestsOnDeath(event)
    end
end)

script.on_event(defines.events.on_player_respawned, function(event)
    if not ENABLE_SEPARATE_SPAWNS then
        PlayerRespawnItems(event)
    else 
        SeparateSpawnsPlayerRespawned(event)
    end

    if ENABLE_LONGREACH then
        GivePlayerLongReach(game.players[event.player_index])
    end
end)

script.on_event(defines.events.on_player_left_game, function(event)
    if ENABLE_SEPARATE_SPAWNS then
        FindUnusedSpawns(event)
    end
end)

script.on_event(defines.events.on_built_entity, function(event)
    if ENABLE_AUTOFILL then
        Autofill(event)
    end
end)



----------------------------------------
-- On Research Finished
----------------------------------------
script.on_event(defines.events.on_research_finished, function(event)
    if FRONTIER_ROCKET_SILO_MODE then
        RemoveRocketSiloRecipe(event)
    end
end)
