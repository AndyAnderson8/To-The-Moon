--[[
NOTES

Maybe prestige means go to next planet to moon or next planet to sun
Cash is total earned distance but you spend it
Have page to view overall distance stats
  compare in terms of planets
graphics is earth with phone being thrown into the air when detected?
upgrades are buying extra phones
  animation of two phones being thrown when phone is thrown
  afterburners
  gravity coil
  might have to convert that to quadratics too, possibly reduce/rebalance other boost


]]

local widget = require("widget") -- not used yet until buttons added
local display = require("display") 
-------------------------------------SETTINGS----------------------------------------------

--MULTIPLIER-EQUATION----
local quadraticA = 1/32
local quadraticExp = 3
local quadraticB = 0
local quadraticC = 1

local maximumAcceleration = 0.05
local minimumAirTime = 0.1 --minimum seconds (prevents misdetects and fake throws)

local accelerationOfGravity = -9.80665 --in meters per second, but can change if you want

local backgroundMusic = audio.loadSound("assets/purrple-cat-space-rain.mp3")
local throwSound = audio.loadSound("assets/forward.mp3")
local catchSound = audio.loadSound("assets/reverse.mpr")

--------------------------------------VARIABLES---------------------------------------------------

local activeDistanceMultiplier = 1 --just for testing, move back to 1
local activeCashMultiplier = 1 --determined by something else, dont change here

local bank = 0

local currentCash = 0
local lastCash = 0
local bestCash = 0 -- in one throw
local maximumCash = 0 -- highest balance
local totalCash = 0

local currentAirtime = 0
local lastAirtime = 0
local bestAirtime = 0
local totalAirtime = 0

local currentRealDistance = 0  --use for active calculation for scores animation
local lastRealDistance = 0
local bestRealDistance = 0
local totalRealDistance = 0

local currentEarnedDistance = 0 --use for active calculation for scores animation
local lastEarnedDistance = 0
local bestEarnedDistance = 0
local totalEarnedDistance = 0

local musicEnabled = false
local sfxEnabled = false

---------------------------------------------TEXT-------------------------------------------------------

local bankText = display.newText("$0.00", display.contentCenterX, -50, native.systemFont, 40)
local totalEarnedDistanceText = display.newText("Total Distance: 0.00 m.", display.contentCenterX, 0, native.systemFont, 20)

local currentEarnedDistanceText = display.newText("0.00 m.", display.contentCenterX - 60, 200, native.systemFont, 50)
local cashMultiplierText = display.newText("x1.0", display.contentCenterX + 100, 200, native.systemFont, 50)
local currentCashText = display.newText("$0.00", display.contentCenterX, 300, native.systemFont, 70)
cashMultiplierText:setFillColor(0, 1, 1)
currentCashText:setFillColor(0, 1, 0)

---------------------------------------UTILITY-FUNCTIONS--------------------------------------------------

---I think this is needed for some reason for wait function (https://docs.coronalabs.com/api/library/timer/performWithDelay.html)
local function listener(event)
  print("listener called")
end

---Lua doesn't have a sleep function, so here's this cause I'm used to RBLX Lua
local function wait(seconds)
  timer.performWithDelay(seconds * 1000, listener)
end

--rounds down and adds commas, fixes formatting too
local function numberCleaner(number, decimalCount)
  if number - math.floor(number) == 0 then -- no decimals
    number = math.floor(number)
    if decimalCount > 0 then
      number = number .. "."
      for i = 1, decimalCount, 1 do
        number = number .. "0"
      end
    end
    return number
  end
  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  int = int:reverse():gsub("(%d%d%d)", "%1,")
  return minus .. int:reverse():gsub("^,", "") .. string.sub(fraction, 1, decimalCount + 1)
end

local function calculateDistance(seconds) --might have to change to real distance if I need to make earnedDistance a quadratic too
  local initialVelocity = -accelerationOfGravity * seconds
  local displacement = initialVelocity * seconds + 0.5 * accelerationOfGravity * seconds^2
  return displacement
end

local function calculateCash(distance)
  return distance * (quadraticA * distance^quadraticExp + quadraticB * distance + quadraticC)
end

--- reloads text, add more as needed
local function updateTextBanners()
  bankText.text = "$" .. numberCleaner(bank, 2)
  totalEarnedDistanceText.text = "Total Distance: " .. numberCleaner(totalEarnedDistance, 2) .. " m." -- broken cause cant load altitude
end

local function updateTextWheels()
  currentEarnedDistanceText.text = numberCleaner(currentEarnedDistance, 2) .. " m."
  cashMultiplierText.text = "x" .. numberCleaner(activeCashMultiplier, 1)
  currentCashText.text = "$" .. numberCleaner(currentCash, 2)
end

local function resetCurrentVariables()
  currentAirtime = 0
  currentRealDistance = 0
  currentEarnedDistance = 0
  currentCash = 0
  activeCashMultiplier = 1
end

--manage all stat updating and reloading
local function manageStats()
  lastAirtime = currentAirtime
  totalAirtime = totalAirtime + lastAirtime
  if lastAirtime > bestAirtime then
    bestAirtime = lastAirtime
  end
  lastRealDistance = currentRealDistance
  totalRealDistance = totalRealDistance + lastRealDistance
  if lastRealDistance > bestRealDistance then
    bestRealDistance = lastRealDistance
  end
  lastEarnedDistance = lastRealDistance * activeDistanceMultiplier
  totalEarnedDistance = totalEarnedDistance + lastEarnedDistance
  if lastEarnedDistance > bestEarnedDistance then
    bestEarnedDistance = lastEarnedDistance
  end
  totalCash = totalCash + currentCash
  bank = bank + currentCash
  if currentCash > bestCash then
    bestCash = currentCash --this is one throw max
  end
  if bank > maximumCash then
    maximumCash = bank --this is total cash in bank
  end
  resetCurrentVariables()
end

--goes to near 0 when dropped, near 1 when sitting
local function onAccelerate(event)
  local acceleration = math.sqrt(event.xRaw^2 + event.yRaw^2 + event.zRaw^2)
  if acceleration < maximumAcceleration then
    if sfxEnabled == true then
      audio.play(throwSound)
    end
    currentAirtime = currentAirtime + event.deltaTime
    currentRealDistance = calculateDistance(currentAirtime)
    currentEarnedDistance = currentRealDistance * activeDistanceMultiplier
    currentCash = calculateCash(currentRealDistance)
    activeCashMultiplier = numberCleaner(currentCash / currentRealDistance, 1)
    updateTextWheels() -- might be causing lag
  else
    if currentAirtime > minimumAirTime then
      if sfxEnabled == true then
        audio.play(catchSound)
      end
      manageStats()
      updateTextBanners()
    else
      resetCurrentVariables()
    end
  end
end

Runtime:addEventListener("accelerometer", onAccelerate)

if musicEnabled == true then
  audio.play(backgroundMusic, {channel = 1, loops = -1, fadein = 500})
end

--[[
display.setDefault("textureWrapX", "repeat")
display.setDefault("textureWrapY", "mirroredRepeat")
local bg = display.newRect(display.contentCenterX, display.contentCenterY, 1024, 1024);
bg.fill = {type = "image", filename = "assets/space_bg.png"};
display.setDefault("textureWrapX", "clampToEdge")
display.setDefault("textureWrapY", "clampToEdge")
display.anchorY = 210
]]