local miningZone = false
local isMining = false
local MiningLocation = Config.Blips.MiningLocation
local WashLocation = Config.Blips.WashLocation
local SmeltLocation = Config.Blips.SmeltLocation
local SellLocation = Config.Blips.SellLocation
RegisterNetEvent('esx-mining:getMiningstage', function(stage, state, k)
  Config.MiningLocation[k][stage] = state
end)

local function loadAnimDict(dict)
  while (not HasAnimDictLoaded(dict)) do
      RequestAnimDict(dict)
      Wait(3)
  end
end

local function StartMining(mining)
  local animDict = "melee@hatchet@streamed_core"
  local animName = "plyr_rear_takedown_b"
  local Ped = PlayerPedId()
  local miningtimer = MiningJob.MiningTimer
  isMining = true
  TriggerEvent('esx-mining:miningwithaxe')
  ESX.Progressbar(Config.Text['Mining_ProgressBar'], miningtimer, {
    FreezePlayer = true,
    animation = {
      type = 'anim',
      dict = animDict,
      lib = animName
    },
    onFinish = function()
      ClearPedTasks(Ped)
      TriggerServerEvent('esx-mining:setMiningStage', "isMined", true, mining)
      TriggerServerEvent('esx-mining:setMiningStage', "isOccupied", false, mining)
      TriggerServerEvent('esx-mining:receivedStone')
      TriggerServerEvent('esx-mining:setMiningTimer')
      isMining = false
      DetachEntity(pickaxeprop, 1, true)
      DeleteEntity(pickaxeprop)
    end, onCancel = function()
      ClearPedTasks(Ped)
      TriggerServerEvent('esx-mining:setMiningStage', "isOccupied", false, mining)
      isMining = false
      DetachEntity(pickaxeprop, 1, true)
      DeleteEntity(pickaxeprop)
      DeleteObject(pickaxeprop)
    end
  })

    
  TriggerServerEvent('esx-mining:setMiningStage', "isOccupied", true, mining)
  CreateThread(function()
      while isMining do
          loadAnimDict(animDict)
          TaskPlayAnim(trClassic, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
          Wait(3000)
      end
  end)
end

RegisterCommand("stone", function()
  TriggerServerEvent('esx-mining:receivedStone')
end)

RegisterNetEvent('esx-mining:miningwithaxe', function()
  local ped = PlayerPedId()
  trpickaxeprop = CreateObject(GetHashKey("prop_tool_pickaxe"), 0, 0, 0, true, true, true)        
  AttachEntityToEntity(trpickaxeprop, ped, GetPedBoneIndex(ped, 57005), 0.17, -0.04, -0.04, 180, 100.00, 120.0, true, true, false, true, 1, true)
  Wait(MiningJob.MiningTimer)
  DetachEntity(trpickaxeprop, 1, true)
  DeleteEntity(trpickaxeprop)
end)

RegisterNetEvent('esx-mining:getpickaxe', function()
  TriggerServerEvent('esx-mining:BuyPickaxe')
end)

RegisterNetEvent('esx-mining:getPan', function()
  TriggerServerEvent('esx-mining:BuyWash')
end)

RegisterNetEvent('esx-mining:minermenu', function()
  local elements = {
    {unselectable = true, icon = '', title = Config.Text['MenuHeading']},
    {icon = '', title = 'Buy a pickaxe', description = Config.Text['PickAxeText'], value = 'mine'}
  }

  ESX.OpenContext('right', elements, function(menu, element)
    if element.value == 'mine' then
      TriggerEvent('esx-mining:getpickaxe')
      ESX.CloseContext()
    end
  end, function(menu)
    ESX.CloseContext()
  end)
end)

RegisterNetEvent('esx-mining:panmenu', function()
  local elements = {
    {unselectable = true, icon = '', title = Config.Text['WashHeading']},
    {icon = '', title = 'Buy a wash pan', description = Config.Text['PanText'], value = 'pan'}
  }

  ESX.OpenContext('right', elements, function(menu, element)
    if element.value == 'pan' then
      TriggerEvent('esx-mining:getPan')
      ESX.CloseContext()
    end
  end, function(menu)
    ESX.CloseContext()
  end)
end)

RegisterNetEvent('esx-mining:smeltmenu', function()
  local elements = {
    {unselectable = true, icon = '', title = Config.Text['SmethHeading']},
    {icon = '', title = Config.Text['smelt_IText'], description = 'Smelt your iron down',value = 'iron'},
    {icon = '', title = Config.Text['smelt_CText'], description = 'Smelt your copper down', value = 'copper'},
    {icon = '', title = Config.Text['smelt_GText'], description = 'Smelt 4 gold nuggets into 1 gold bar', value = 'gold'},
  }

  ESX.OpenContext('right', elements, function(menu, element)
    if element.value == 'iron' then
      TriggerEvent('esx-mining:SmeltIron')
      ESX.CloseContext()
    end
    if element.value == 'copper' then
      TriggerEvent('esx-mining:SmeltCopper')
      ESX.CloseContext()
    end
    if element.value == 'gold' then
      TriggerEvent('esx-mining:SmeltGold')
      ESX.CloseContext()
    end
  end, function(menu)
    ESX.CloseContext()
  end)
end)

RegisterNetEvent('esx-mining:mine', function(data)
  local mining = data.location
  --if not Config.MiningLocation[mining]["isMined"] and not Config.MiningLocation[mining]["isOccupied"] then
    ESX.TriggerServerCallback('esx-mining:pickaxe', function(PickAxe)
      if PickAxe then
        StartMining(mining)
      elseif not PickAxe then
        ESX.ShowNotification(Config.Text['error_mining'])
      end
    end)
  --end
end)

RegisterNetEvent('esx-mining:washingrocks', function()
  ESX.TriggerServerCallback('esx-mining:washpan', function(washingpancheck)
    if washingpancheck then
      ESX.TriggerServerCallback('esx-mining:stonesbruf', function(stonesbruf)
        if stonesbruf then
          local playerPed = PlayerPedId()
          local coords = GetEntityCoords(playerPed)
          local rockwash = MiningJob.WashingTimer
          ESX.Progressbar(Config.Text['Washing_Rocks'], rockwash, {
            FreezePlayer = true,
            animation = {
              type = 'Scenario',
              Scenario = 'WORLD_HUMAN_BUM_WASH'
            },
            onFinish = function()
              ClearPedTasks(PlayerPedId())
              TriggerServerEvent("esx-mining:receivedReward")
            end, onCancel = function()
              ClearPedTasks(PlayerPedId())
              ESX.ShowNotification(Config.Text['cancel'])
            end       
          })
        else
          ESX.ShowNotification(Config.Text['error_minerstone'])
        end
      end)
    else
      Wait(500)
      ESX.ShowNotification(Config.Text['error_washpan'])
    end
  end)
end)

RegisterNetEvent('esx-mining:SmeltIron', function()
  ESX.TriggerServerCallback('esx-mining:IronCheck', function(IronCheck)
    if IronCheck then
      local iron = MiningJob.IronTimer
      ESX.Progressbar(Config.Text['smelt_iron'], iron, {
        FreezePlayer = true,
        animation = {
          type = 'anim',
          dict = 'amb@world_human_stand_fire@male@idle_a',
          lib = 'idle_a'
        },
        onFinish = function()
          ClearPedTasks(PlayerPedId())
          TriggerServerEvent('esx-mining:IronBar')
        end, onCancel = function()
          ClearPedTasks(PlayerPedId())
          ESX.ShowNotification(Config.Text['cancel'])
        end
      })
    else
      ESX.ShowNotification(Config.Text['error_ironCheck'])
    end
  end)
end)

RegisterNetEvent('esx-mining:SmeltCopper', function()
  ESX.TriggerServerCallback('esx-mining:CopperCheck', function(CopperCheck)
    if CopperCheck then
      local copper = MiningJob.CopperTimer
      ESX.Progressbar(Config.Text['smelt_copper'], copper, {
        FreezePlayer = true,
        animation = {
          type = 'anim',
          dict = 'amb@world_human_stand_fire@male@idle_a',
          lib = 'idle_a'
        },
        onFinish = function()
          ClearPedTasks(PlayerPedId())
          TriggerServerEvent('esx-mining:CopperBar')
        end, onCancel = function()
          ClearPedTasks(PlayerPedId())
          ESX.ShowNotification(Config.Text['cancel'])
        end
      })
    else
      ESX.ShowNotification(Config.Text['error_copperCheck'])
    end
  end)
end)

RegisterNetEvent('esx-mining:SmeltGold', function()
  ESX.TriggerServerCallback('esx-mining:GoldCheck', function(GoldCheck)
    if GoldCheck then
      local gold = MiningJob.GoldTimer
      ESX.Progressbar(Config.Text['smelt_gold'], gold, {
        FreezePlayer = true,
        animation = {
          type = 'anim',
          dict = 'amb@world_human_stand_fire@male@idle_a',
          lib = 'idle_a'
        },
        onFinish = function()
          ClearPedTasks(PlayerPedId())
          TriggerServerEvent('esx-mining:GoldBar')
        end, onCancel = function()
          ClearPedTasks(PlayerPedId())
          ESX.ShowNotification(Config.Text['cancel'])
        end
      })
    else
      ESX.ShowNotification(Config.Text['error_goldCheck'])
    end
  end)
end)

RegisterNetEvent('esx-mining:sellItems', function()
  TriggerServerEvent('esx-mining:Seller')
end)

CreateThread(function()
  for k, v in pairs(Config.MiningLocation) do

    exports.ox_target:addBoxZone({
      coords = v.coords,
      size = vec3(3.5,3,2),
      rotation = 15,
      debug = drawZones,
      options = {
        {
          name = "Mining"..k,
          event = "esx-mining:mine",
          icon = "Fas Fa-hands",
          label = 'Start Mining',
          canInteract = function(entity, distance, coords, name)
            return true
          end
        }
      }
    })
  end
  exports.ox_target:addBoxZone({
    coords = MiningLocation.targetZone,
    size = vec3(1,1,1),
    rotation = MiningLocation.targetHeading,
      debug = drawZones,
      options = {
        {
          name ='MinerBoss',
          event = "esx-mining:minermenu",
          icon = "Fas Fa-hands",
          label = Config.Text['MenuTarget'],
          canInteract = function(entity, distance, coords, name)
            return true
          end
        }
      }
  })
  exports.ox_target:addBoxZone({
    coords = WashLocation.targetZone,
    size = vec3(1,1,1),
    rotation = WashLocation.targetHeading,
    debug = drawZones,
    options = {
      {
        name = 'PanWasher',
        event = "esx-mining:panmenu",
        icon = "Fas Fa-hands",
        label = Config.Text['Menu_pTarget'],
        canInteract = function(entity, distance, coords, name)
          return true
        end
      },
    },
  })
  exports.ox_target:addBoxZone({
    coords = vec3(54.77, 3160.31, 25.62),
    size =  vec3(2,2,2),
    rotation = 155,
    debug = drawZones,
    options = {
      {
        name = "Water",  
        event = "esx-mining:washingrocks",
        icon = "Fas Fa-hands",
        label = Config.Text['Washing_Target'],
        canInteract = function(entity, distance, coords, name)
          return true
        end
      }
    }
  })
 -- Smelt ox_target         
  exports.ox_target:addBoxZone({
    coords = vec3(1086.3, -2003.96, 30.88),
    size = vec3(3.9, 4, 4),
    rotation = 322,
    debug = drawZones,
    options = {
      {
        name = "smelt",  
        event = "esx-mining:smeltmenu",
        icon = "Fas Fa-hands",
        label = Config.Text['Smeth_Rocks'],
        canInteract = function(entity, distance, coords, name)
            return true
        end
      }
    }
  })

  -- Seller ox_target 
  exports.ox_target:addBoxZone({
    coords = vec3(SellLocation.targetZone),
    size = vec3(2, 2, 2),
    rotation = SellLocation.targetHeading,
    debug = drawZones,
    options = {
      {
        name = "Seller",
        event = "esx-mining:sellItems",
        icon = "Fas Fa-hands",
        label = Config.Text['Seller'],
        canInteract = function(entity, distance, coords, name)
          return true
        end
      }
    } 
  })
end)
