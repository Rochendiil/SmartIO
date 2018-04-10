savedmoves = {}
goodcombo = {}
buttonpress = {}
tempcombos = {}
writetimer = 0
runtime = 0
write = 1
Deathcounter = 0
aantalmeter = 0
printmeter = 0
airtime = 0
coins = 0
function buttonpress.new(Button, Presstime, Jump, Direction)
  local self = {}
  self.btn = Button
  self.presstime = Presstime
  self.jump = Jump
  self.direction = Direction
  return self
end

local MarioX = 0x000094
local subMarioX = 0x000095
fitness = 0
prevfitness = 0
timer = 0
move = 0
nummer = 1
movecount = 1
pressbuttondone = false
tempcombotext = 0
savedcombotext = 0
failtimer = 0
walltimer = 0

function MakeDeath()
  movecount = 0
  file = io.open("fitness.txt", "a+")
  io.output(file)
  io.write("Fitness: " .. fitness)
  io.write("\n")
  io.close(file)
  getcoins()
  aantalmeter = memory.readbyte(0x000095) * 20
  aantalmeter = math.ceil(memory.readbyte(0x000094) / 20) + aantalmeter
  aantalmeter = aantalmeter/ 100
  printmeter = aantalmeter + printmeter
  savestate.load("DP1.State")
end


function Pressbutton(Button, x, y, jump)
  joypad.set({Y=1}, 1)
  if jump then
    joypad.set({B=1}, 1)
  end

  if timer > x and timer <= y then
    joypad.set(Button, 1)
  end

  if timer > y then
    if movecount >= table.getn(tempcombos) then
      print("Trigger timer")
      move = 0

      if fitness <= prevfitness then
        for k=1, #tempcombos do
          tempcombos[k] = nil
        end
        nummer = nummer + 1
        MakeDeath()
      end

      if fitness > prevfitness then
        table.insert(savedmoves, tempcombos[table.getn(tempcombos)])
        for k=1, #tempcombos do
          tempcombos[k] = nil
        end
        prevfitness = fitness
        move = 0
        nummer = 1
        failtimer = 0
        MakeDeath()
      end
    end

    movecount = movecount + 1

    timer = 0
    index = 1
    joypad.set(Button, 0)

    if nummer == 4 then
      nummer = 1
    end
  end
end

function getmove()
  if table.getn(tempcombos) == 0 then
    for k=1, #savedmoves do
      table.insert(tempcombos, savedmoves[k])
    end
  end
  savedcombotext = table.getn(savedmoves)
  if move == 0 then
    press = math.random(20,140)
    if nummer == 1 then
      local button = buttonpress.new({Right=1},press, false, "right")
      table.insert(tempcombos, button)
    end
    if nummer == 2 then
      local button = buttonpress.new({Right=1},120, true, "right up")
      table.insert(tempcombos, button)
    end
    if nummer == 3 then
      local button = buttonpress.new({Left=1},press, false, "left")
      table.insert(tempcombos, button)
    end
    if nummer == 4 then
      local button = buttonpress.new({Left=1},120, true, "left up")
      table.insert(tempcombos, button)
    end
    move = 1
  end
  if move == 1 then
    tempcombotext = table.getn(tempcombos)
    if table.getn(tempcombos) == table.getn(savedmoves) + 1 then
      Pressbutton(tempcombos[movecount].btn, 0, tempcombos[movecount].presstime, tempcombos[movecount].jump, tempcombos[movecount].direction)
    end
  end
end

--- Checkt of mario's animatie afgaat
function ResetIfDeath()
  if memory.readbyte(0x00007B) < 5 then
    joypad.set({B=1}, 1)
  end
  if memory.readbyte(0x00148F) == 1 then
    print("Trigger shell")
    joypad.set({Y=1}, 0)
    joypad.set({Y=1}, 1)
  end
  if memory.readbyte(0x000071) == 9 then
    print("Trigger death")
    nummer = nummer + 1
    failtimer = failtimer + 1
    move = 0
    movecount = 1
    timer = 0
    if failtimer > 5 then
      table.remove(savedmoves[table.getn(savedmoves)])
      print("Trigger failtimer")
      failtimer = 0
    end
    table.remove(savedmoves[table.getn(savedmoves)])
    print("Removed last from savedtable")
    for k=1, #tempcombos do
      tempcombos[k] = nil
    end
    gui.text(20,80,"Mario is dood")
    Deathcounter = Deathcounter + 1
    savestate.load("DP1.State")
  end
end
function writeto()
  create()
end
function getcoins()
  coins = memory.readbyte(0x000F14) + coins
end
function checkifair()
  if memory.readbyte(0x00008D) == 0 then
    airtime = 0.02 + airtime
  end
end
function create()
    file = io.open("info2.txt", "w")
    io.output(file)
    ---io.write("Deaths: 0\nKM: 0\nRuntime: 0\nAirtime: 0\nEnemies: 0")
    io.write("Deaths: " .. Deathcounter)
    io.write("\nKM: " .. printmeter)
    io.write("\nRuntime: " .. math.ceil(runtime))
    io.write("\nAirime: " .. math.ceil(airtime))
    io.write("\nCoins: " .. coins)
    io.close(file)
  end
  function createfitness()
    file = io.open("fitness.txt", "w")
    io.output(file)
    io.write("")
    io.close(file)
  end
create()
createfitness()
while true do
  --- Hieronder wordt de xcoördienaten van mario uitgelezen
  writetimer = writetimer + 1
  if writetimer == 50 then
    writeto()
    writetimer = 0
  end
  checkifair()
  marx = memory.readbyte(0x000094)
  submarx = memory.readbyte(0x000095) * 255
  fitness = marx + submarx
  runtime = 0.02 + runtime


  --- Print de Gui
  gui.text(20,200, "writetimer: " .. writetimer)
  gui.text(20,40, "prevfitness: " .. prevfitness)
  gui.text(20,20, "Fitness: " .. fitness)
  gui.text(20,60, "MarioSubpos: " .. memory.readbyte(0x000095))
  gui.text(20,80,"TempLength: " .. tempcombotext)
  gui.text(180,80,"SavedLength: " .. savedcombotext)
  gui.text(20,100,"Move: " .. move)
  gui.text(20,120,"Timer: " .. timer)
  gui.text(20,140,"Nummer: " .. nummer)
  gui.text(20,160,"Movecount: " .. movecount)
  gui.text(20,180,"Failtimer: " .. failtimer)
  ResetIfDeath()
  getmove()
  timer = timer + 1
  emu.frameadvance()
end
