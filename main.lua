local player =  {
    x = 80,
    y = 0,
    width = 1,
    height = 1,
    velocityY = 0,
    isJumping = false
}

local ground = { y = 0, height = 40 }
local obstacles = {}
local spawnTimer = 0
local spawnInterval = 1.5
local gameSpeed = 300
local score = 0
local highScore = 0
local gameOver = false
local gravity = 1200
local jumpForce = -500

local images = {}
local cactusImages = {}
local dinoScale = 1
local highScoreFile = "highscore.dat"
local messageFontSize = 45
local messageFont
local baseFont
local bgmSource
local motivationalMessages = {
    "gng stop tweaking",
    "ts pmo fr fr",
    "you sussy baka",
    "meow :3",
    "bruh"
}
local currentMessage = ""
local messageTimer = 0
local messageInterval = 3

local function fileExists(path)
    if love.filesystem.getInfo then
        return love.filesystem.getInfo(path) ~= nil
    elseif love.filesystem.exists then
        return love.filesystem.exists(path)
    end
    return false
end

local function shouldFlip()
    return math.floor(score / 200) % 2 == 1
end

local function pickMotivation()
    if #motivationalMessages == 0 then return end
    local nextMessage = motivationalMessages[math.random(#motivationalMessages)]
    if currentMessage ~= "" and #motivationalMessages > 1 then
        while nextMessage == currentMessage do
            nextMessage = motivationalMessages[math.random(#motivationalMessages)]
        end
    end
    currentMessage = nextMessage
end

local function loadHighScore()
    if fileExists(highScoreFile) then
        local saved = love.filesystem.read(highScoreFile)
        local value = tonumber(saved)
        if value then
            highScore = value
        end
    end
end

local function saveHighScore()
    love.filesystem.write(highScoreFile, tostring(math.floor(highScore)))
end

local function loadCactusImages()
    local variants = {
        "assets/sussy_gun.png",
        "assets/sussy_knife.png",
    }

    for _, path in ipairs(variants) do
        if fileExists(path) then
            table.insert(cactusImages, love.graphics.newImage(path))
        end
    end

    if #cactusImages == 0 then
        cactusImages[1] = love.graphics.newImage("assets/sussy_gun.png")
    end
end

function love.load()
    love.window.setTitle("Haxmass :3")
    love.filesystem.setIdentity("haxmass")
    images.dino = love.graphics.newImage("assets/sussy_player.png")
    loadCactusImages()
    loadHighScore()
    pickMotivation()

    local bgmPath = "assets/goofy_ahh_bgm.wav"
    if fileExists(bgmPath) then
        bgmSource = love.audio.newSource(bgmPath, "static")
        bgmSource:setLooping(true)
        bgmSource:setVolume(0.6)
        bgmSource:play()
    end

    local targetHeight = 60
    dinoScale = targetHeight / images.dino:getHeight()
    player.width = images.dino:getWidth() * dinoScale
    player.height = targetHeight

    ground.y = love.graphics.getHeight() - ground.height
    player.y = ground.y - player.height + 1

    baseFont = love.graphics.newFont(20)
    love.graphics.setFont(baseFont)
    messageFont = love.graphics.newFont(messageFontSize)
end

function love.update(dt)
    if gameOver then return end

    messageTimer = messageTimer + dt
    if messageTimer >= messageInterval then
        messageTimer = messageTimer - messageInterval
        pickMotivation()
    end
    
    score = score + dt * 10
    gameSpeed = 300 + score * 0.5
    
    if player.isJumping then
        player.velocityY = player.velocityY + gravity * dt
        player.y = player.y + player.velocityY * dt
        
        if player.y >= ground.y - player.height then
            player.y = ground.y - player.height + 1
            player.isJumping = false
            player.velocityY = 0
        end
    end
    
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnInterval = math.random(10, 20) / 10
        spawnObstacle()
    end
    
    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.x = obs.x - gameSpeed * dt
        
        if obs.x + obs.width < 0 then
            table.remove(obstacles, i)
        end
        
        if checkCollision(player, obs) then
            gameOver = true
            if score > highScore then
                highScore = score
                saveHighScore()
            end
        end
    end
end

function love.draw()
    local flipped = shouldFlip()
    local bg = flipped and {1, 1, 1} or {0, 0, 0}
    local fg = flipped and {0, 0, 0} or {1, 1, 1}

    love.graphics.clear(bg[1], bg[2], bg[3])
    
    if flipped then
        love.graphics.push()
        love.graphics.translate(love.graphics.getWidth(), 0)
        love.graphics.scale(-1, 1)
    end

    love.graphics.setColor(fg[1], fg[2], fg[3])
    love.graphics.line(0, ground.y, love.graphics.getWidth(), ground.y)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.dino, player.x, player.y, 0, dinoScale, dinoScale)
    
    for _, obs in ipairs(obstacles) do
        love.graphics.draw(obs.image, obs.x, obs.y, 0, obs.scale, obs.scale)
    end

    if flipped then
        love.graphics.pop()
    end
    
    love.graphics.setColor(fg[1], fg[2], fg[3])
    love.graphics.print("Score: " .. math.floor(score), 10, 10)
    love.graphics.print("High Score: " .. math.floor(highScore), 10, 35)
    love.graphics.setFont(messageFont)
    love.graphics.print(currentMessage, love.graphics.getWidth() / 2 - messageFont:getWidth(currentMessage) / 2, 60)
    love.graphics.setFont(baseFont)
    
    if gameOver then
        love.graphics.setColor(fg[1], fg[2], fg[3], 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(bg[1], bg[2], bg[3])
        love.graphics.print("GAME OVER", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 - 30)
        love.graphics.print("Press SPACE to restart", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 + 10)
    end
end

function love.keypressed(key)
    if key == "space" or key == "up" then
        if gameOver then
            restartGame()
        elseif not player.isJumping then
            player.isJumping = true
            player.velocityY = jumpForce
        end
    end
    
    if key == "escape" then
        love.event.quit()
    end
end

function spawnObstacle()
    local image = cactusImages[math.random(#cactusImages)]
    local targetHeight = 50
    local scale = targetHeight / image:getHeight()

    local obstacle = {
        x = love.graphics.getWidth(),
        width = image:getWidth() * scale,
        height = targetHeight,
        image = image,
        scale = scale
    }
    obstacle.y = ground.y - obstacle.height + 1
    table.insert(obstacles, obstacle)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

function restartGame()
    gameOver = false
    score = 0
    obstacles = {}
    spawnTimer = 0
    gameSpeed = 300
    player.y = ground.y - player.height + 1
    player.isJumping = false
    player.velocityY = 0
end
