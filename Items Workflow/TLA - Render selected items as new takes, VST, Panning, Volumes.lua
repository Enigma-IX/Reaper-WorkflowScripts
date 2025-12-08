--[[
 * ReaScript Name: Render selected items with their track's FX, volume, and pan settings,
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-01-28)
  + Initial Release
--]]

function Msg(param)
    reaper.ShowConsoleMsg(tostring(param) .. "\n")
end

reaper.Undo_BeginBlock()

local num_selected_items = reaper.CountSelectedMediaItems(0)

if num_selected_items == 0 then
    Msg("No items selected")
    return
end

local track_settings = {}

local selected_items = {}
for i = 0, num_selected_items - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item and reaper.ValidatePtr(item, "MediaItem*") then
        table.insert(selected_items, item)
    else
        Msg("Error: Invalid media item detected at index " .. i)
    end
end

for _, item in ipairs(selected_items) do
    local track = reaper.GetMediaItemTrack(item) 

    if not track or not reaper.ValidatePtr(track, "MediaTrack*") then
        Msg("Error: Item has no associated track!")
        goto continue
    end

    if not track_settings[track] then
        local vol = reaper.GetMediaTrackInfo_Value(track, "D_VOL") 
        local pan = reaper.GetMediaTrackInfo_Value(track, "D_PAN") 
        local fx_enabled = reaper.TrackFX_GetCount(track) > 0 

        track_settings[track] = {
            vol = vol,
            pan = pan,
            fx_enabled = fx_enabled
        }
    end

    reaper.Main_OnCommand(40289, 0)
    reaper.SetMediaItemSelected(item, true)

    reaper.Main_OnCommand(41823, 0)

    reaper.SetMediaItemSelected(item, false)

    ::continue:: 
end

for _, item in ipairs(selected_items) do
    reaper.SetMediaItemSelected(item, true)
end

for track, settings in pairs(track_settings) do
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", settings.vol)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", settings.pan)

    if settings.fx_enabled then
        reaper.TrackFX_Delete(track, 0)
    end
end

reaper.Undo_EndBlock("Render selected items with track settings", -1)
