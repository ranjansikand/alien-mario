--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}
    local flagObjects = {}

    local keySpawned = false
    local keyObtained = false
    local keyColor = math.random(4)

    local lockSpawned = false
    local lockBumped = false
    local lockColor = keyColor + 4

    local lockLocation = math.random(10, 30)
    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(6) == 1 and not (x < 3 or x > width - 2) then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and not (x > width - 2) and not (x == lockLocation) then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 and not (x > width - 2) then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end


            -- key spawning
            if (math.random(3) == 1) and (keySpawned == false) and x > 5 then
                -- only issue is there's no guarantee it will spawn
                local key = GameObject {
                texture = 'locks-and-keys',
                x = (x - 1) * TILE_SIZE,
                y = (2) * TILE_SIZE,
                width = 16,
                height = 16,
                frame = keyColor,
                collidable = true,
                consumable = true,
                solid = false,
                onConsume = function(player, object)
                    gSounds['pickup']:play()
                    player.score = player.score + 100

                    keyObtained = true
                end
                }
                keySpawned = true
                table.insert(objects, key)
            end
            -- end key spawning

            if x == lockLocation - 1 and lockSpawned == false then
                local lock = GameObject {
                    texture = 'locks-and-keys',
                    x = (x) * TILE_SIZE,
                    y = (3) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = lockColor,
                    collidable = true,
                    consumable = false,
                    solid = true,
                    name = 'lock',
                    remove = false, 
                    onCollide = function(obj)
                        if keyObtained == false then
                            gSounds['empty-block']:play()
                        else
                            obj.remove = true
                            gSounds['pickup']:play()
                            

                            flagObjects = makeFlag(width-1, width)
                            for k, obj in pairs(flagObjects) do
                                table.insert(objects, obj)
                            end
                        end
                    end
                }
                lockSpawned = true
                table.insert(objects, lock) 
            end
            
            -- chance to spawn a block
            if math.random(10) == 1 and not (x > width - 2) and not (x == lockLocation) then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
            -- if x == width - 1 then
            --     flagObjects = makeFlag(x, width)
            --     for k, obj in pairs(flagObjects) do
            --         table.insert(objects, obj)
            --     end
            -- end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end


-- keeps the main functions cleaner to put this separately
-- it was easier to make a function than I expected
function makeFlag(x, width)
    local flagObjects = {}
    flagColor = math.random(6) -- for post
    wavingColor = math.random(4)

    if wavingColor == 1 then
        wavingColor = 7
    elseif wavingColor == 2 then
        wavingColor = 16
    elseif wavingColor == 3 then
        wavingColor = 25
    else
        wavingColor = 34
    end

    local flagTop = GameObject {
        texture = 'flags',
        x = (x - 1) * TILE_SIZE,
        y = (3) * TILE_SIZE,
        width = 16,
        height = 16,
        frame = flagColor,
        collidable = false,
        consumable = false,
        solid = false
    }
    local flagMiddle = GameObject {
        texture = 'flags',
        x = (x - 1) * TILE_SIZE,
        y = (4) * TILE_SIZE,
        width = 16,
        height = 16,
        frame = flagColor + 9,
        collidable = false,
        consumable = false,
        solid = false,
    }

    local flagBottom = GameObject {
        texture = 'flags',
        x = (x - 1) * TILE_SIZE,
        y = (5) * TILE_SIZE,
        width = 16,
        height = 16,
        frame = flagColor + 9 + 9,
        collidable = true,
        consumable = true,
        solid = false,
        onConsume = function(player, object)
            gSounds['powerup-reveal']:play()
            player.score = player.score + 250
            gStateMachine:change('play',{
                levelWidth = width * 1.5,
                passingScore = player.score
            })
        end
    }
    local wavingPart = GameObject {
        texture = 'flags',
        x = (x) * TILE_SIZE - 7,
        y = (3) * TILE_SIZE + 6,
        width = 16,
        height = 16,
        frame = wavingColor,
        collidable = false,
        consumable = false,
        solid = false,
        animation = Animation {
            frames = {wavingColor, wavingColor+1, wavingColor+2},
            interval = 0.2
        },
        onConsume = function(player, object)
            gSounds['powerup-reveal']:play()
            player.score = player.score + 250
            gStateMachine:change('play',{
                levelWidth = width * 1.5,
                passingScore = player.score
            })
        end
    }
    table.insert(flagObjects, flagTop)
    table.insert(flagObjects, flagMiddle)
    table.insert(flagObjects, flagBottom)
    table.insert(flagObjects, wavingPart)

    return flagObjects
end