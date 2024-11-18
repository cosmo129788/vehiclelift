ESX = nil
ESX = exports["es_extended"]:getSharedObject()

local FLOAT_FORCE = 3.0  -- Set the upward force for the vehicle
local SURFACE_THRESHOLD = 0.2  -- Distance threshold to stop rising when the vehicle is close to the surface
local SURFACE_OFFSET = Config.Vehiclerecovery.surfaceoffsets  -- Fine-tune the position to make it look like the vehicle is floating
local VELOCITY_ZERO_THRESHOLD = 0.1 -- Threshold to stop applying upward force when close to the surface
local FLOAT_DELAY = 50 -- Delay (ms) between checks for vertical movement


-- Helper function to check if a vehicle is underwater
local function isVehicleUnderwater(vehicle)
    local coords = GetEntityCoords(vehicle)
    local waterHeight = GetWaterHeight(coords.x, coords.y, coords.z - 1.0)
    return waterHeight and coords.z < waterHeight
end

-- Function to float the vehicle to the surface
local function floatVehicleToSurface(vehicle)
    if DoesEntityExist(vehicle) then
        Citizen.CreateThread(function()
            local floating = true
            local velocityZ = 0.0

            -- Apply upward force until the vehicle reaches the surface
            while floating do
                local vehicleCoords = GetEntityCoords(vehicle)
                local waterHeight = GetWaterHeight(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)

                if waterHeight then
                    local distanceToSurface = waterHeight - vehicleCoords.z

                    -- If vehicle is underwater, apply upward velocity to bring it up
                    if distanceToSurface > SURFACE_THRESHOLD then
                        -- Apply upward velocity only in Z direction
                        velocityZ = FLOAT_FORCE

                        -- Apply upward velocity directly (no horizontal movement)
                        SetEntityVelocity(vehicle, 0.0, 0.0, velocityZ)

                        -- Prevent the vehicle from rotating/spinning
                        SetEntityRotation(vehicle, 0.0, 0.0, GetEntityRotation(vehicle, 2).z, 2, true)
                    else
                        -- Once the vehicle is near the surface, stop applying upward force
                        SetEntityVelocity(vehicle, 0.0, 0.0, 0.0)

                        -- Fine-tune the vehicle's position to look like it's floating on the surface
                        SetEntityCoords(vehicle, vehicleCoords.x, vehicleCoords.y, waterHeight - SURFACE_OFFSET, false, false, false, true)

                        -- Freeze the vehicle in place, ensuring it stays flat on the water surface
                        FreezeEntityPosition(vehicle, true)

                        floating = false
                    end
                else
                    -- If no valid water height is found, stop floating
                    floating = false
                end

                Citizen.Wait(FLOAT_DELAY)
            end
        end)
    end
end


RegisterCommand("liftbag", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 70)

    if vehicle and isVehicleUnderwater(vehicle) then
        ESX.TriggerServerCallback('esx:getplayerspockets', function(item)
            if item and item.count >= 4 then
                TriggerServerEvent('esx:removeliftbag', 'item_standard', Config.Vehiclerecovery.itemname, Config.Vehiclerecovery.itemamount)

                TriggerEvent("chat:addMessage", {
                    args = { "^2Float bag activated! Bringing the vehicle to the surface." }
                })

                floatVehicleToSurface(vehicle)
            else
                TriggerEvent("chat:addMessage", {
                    args = { "^1You don't have enough liftbags! (Requires 4)" }
                })
            end
        end, Config.Vehiclerecovery.itemname)
    else
        TriggerEvent("chat:addMessage", {
            args = { "^1No underwater vehicle nearby!" }
        })
    end
end, false)
