local placedBBQs = {}
local bbqParticles = {}
local bbqFires = {}
local bbqSteaks = {}
local bbqCam = nil
local isBbqCamActive = false

exports('place', function(data, slot)
    if lib.progressCircle({
            duration = Config.timeToPutBbq,
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'mini@repair',
                clip = 'fixing_a_ped'
            },
        })
    then
        exports.ox_inventory:useItem(data, function(data)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)

            local model = `prop_bbq_5`
            lib.requestModel(model)

            local distance = 2.0
            local rad = math.rad(heading)
            local offsetX = coords.x - math.sin(rad) * distance
            local offsetY = coords.y + math.cos(rad) * distance
            local offsetZ = coords.z - 1.0

            local obj = CreateObject(model, offsetX, offsetY, offsetZ, true, true, true)
            SetEntityHeading(obj, heading)
            PlaceObjectOnGroundProperly(obj)
            SetEntityCanBeDamaged(obj, false)

            local netId = NetworkGetNetworkIdFromEntity(obj)
            placedBBQs[netId] = obj

            TriggerServerEvent('old_bbq:addBBQ', netId, coords)

            if Config.enableFire then
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do Wait(10) end

                SetPtfxAssetNextCall("core")
                local fire = StartParticleFxLoopedOnEntity(
                    "fire_wrecked_train",
                    obj,
                    0.0, 0.0, 1.0,
                    0.0, 0.0, 0.0,
                    0.5,
                    false, false, false
                )

                bbqFires[netId] = fire
            end

            if Config.enableSmoke then
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do Wait(10) end
                UseParticleFxAssetNextCall("core")
                local smoke = StartParticleFxLoopedOnEntity(
                    "ent_amb_smoke_general",
                    obj,
                    0.0, 0.0, 0.45,
                    0.0, 0.0, 0.0,
                    0.5,
                    false, false, false
                )
                bbqParticles[netId] = { smoke }
            end
            if Config.steak then
                bbqSteaks[netId] = {}


                local steakModel = `prop_cs_steak`
                lib.requestModel(steakModel)

                local bbqCoords = GetEntityCoords(obj)
                local bbqHeading = GetEntityHeading(obj)


                local offsets = {
                    { x = -0.2, y = -0.2 },
                    { x = 0.2,  y = -0.2 },
                    { x = -0.2, y = 0.2 },
                    { x = 0.2,  y = 0.2 },
                }

                for _, off in ipairs(offsets) do
                    local steak = CreateObject(
                        steakModel,
                        bbqCoords.x + off.x,
                        bbqCoords.y + off.y,
                        bbqCoords.z + 0.95,
                        true, true, true
                    )
                    SetEntityHeading(steak, bbqHeading + math.random(-15, 15))
                    SetEntityCollision(steak, false, false)
                    SetEntityAsMissionEntity(steak, true, true)
                    table.insert(bbqSteaks[netId], steak)
                end
            end
        end)
    else
        lib.notify({ description = 'Vous avez annulé votre action', type = 'error', position = 'top' })
    end
end)


CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for netId, obj in pairs(placedBBQs) do
            if DoesEntityExist(obj) then
                local pos = GetEntityCoords(obj)
                if #(coords - pos) < 2.0 then
                    lib.showTextUI('[E] Cuisiner  \n  [G] Ranger  \n  [F] Regarder')

                    if IsControlJustPressed(0, 38) then
                        local success = lib.progressCircle({
                            duration = Config.timeToUseBbq,
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            },
                            anim = {
                                dict = "amb@prop_human_bbq@male@base",
                                clip = "base"
                            },
                            prop = {
                                model = `prop_fish_slice_01`,
                                bone  = 57005,
                                pos   = vec3(0.12, 0.02, -0.02),
                                rot   = vec3(-80.0, 60.0, 10.0)
                            }
                        })

                        if success then
                            TriggerServerEvent('old_bbq:openStash', netId)
                        else
                            lib.notify({ description = 'Vous avez annulé votre action', type = 'error', position = 'top' })
                        end
                    end

                    if IsControlJustPressed(0, 47) then
                        local success = lib.progressCircle({
                            duration = Config.timeToTakeBbq,
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            },
                            anim = {
                                dict = 'mini@repair',
                                clip = 'fixing_a_ped'
                            },
                        })
                        if success then
                            local resp = lib.callback.await('old_bbq:giveBbq', false)
                            if resp then
                                if Config.enableSmoke then
                                    if bbqParticles[netId] then
                                        for _, fx in ipairs(bbqParticles[netId]) do StopParticleFxLooped(fx, 0) end
                                        bbqParticles[netId] = nil
                                    end
                                end
                                if Config.enableFire then
                                    if bbqFires[netId] then
                                        RemoveScriptFire(bbqFires[netId])
                                        bbqFires[netId] = nil
                                    end
                                end
                                if Config.steak then
                                    if bbqSteaks[netId] then
                                        for _, steak in ipairs(bbqSteaks[netId]) do
                                            if DoesEntityExist(steak) then DeleteEntity(steak) end
                                        end
                                        bbqSteaks[netId] = nil
                                    end
                                end
                                if DoesEntityExist(obj) then DeleteEntity(obj) end
                                placedBBQs[netId] = nil
                                TriggerServerEvent('old_bbq:removeBBQ', netId)
                                lib.notify({ description = 'Barbecue rangé !', type = 'success', position = 'top' })
                                local isOpen, text = lib.isTextUIOpen()
                                if isOpen then
                                    lib.hideTextUI()
                                end
                                RenderScriptCams(false, true, 1000, true, true)
                                if bbqCam then
                                    DestroyCam(bbqCam, false)
                                    bbqCam = nil
                                end
                                isBbqCamActive = false
                            else
                                lib.notify({
                                    description = 'Vous n\'avez pas assez de place dans votre inventaire',
                                    type =
                                    'error',
                                    position = 'top'
                                })
                            end
                        else
                            lib.notify({ description = 'Vous avez annulé votre action', type = 'error', position = 'top' })
                        end
                    end

                    if IsControlJustPressed(0, 185) then
                        if not isBbqCamActive then
                            local bbqCoords = GetEntityCoords(obj)
                            bbqCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

                            SetCamCoord(bbqCam, bbqCoords.x, bbqCoords.y - 0.6, bbqCoords.z + 1.2)
                            PointCamAtCoord(bbqCam, bbqCoords.x, bbqCoords.y, bbqCoords.z + 1.0)
                            SetCamActive(bbqCam, true)
                            RenderScriptCams(true, true, 1000, true, true)
                            isBbqCamActive = true
                            lib.notify({
                                description = 'Vous regardez le barbecue le barbecue',
                                type = 'inform',
                                position =
                                'top'
                            })
                        else
                            RenderScriptCams(false, true, 1000, true, true)
                            if bbqCam then
                                DestroyCam(bbqCam, false)
                                bbqCam = nil
                            end
                            isBbqCamActive = false
                            lib.notify({
                                description = 'Vous avez arrêté de regarder le barbecue',
                                type = 'inform',
                                position =
                                'top'
                            })
                        end
                    end
                else
                    local isOpen, text = lib.isTextUIOpen()
                    if isOpen then
                        lib.hideTextUI()
                    end
                end
                if isBbqCamActive then
                    DisableControlAction(0, 30, true)
                    DisableControlAction(0, 31, true)
                    DisableControlAction(0, 21, true)
                    DisableControlAction(0, 22, true)
                    DisableControlAction(0, 23, true)
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 25, true)
                    DisableControlAction(0, 44, true)
                end
            end
        end
    end
end)
