--[[
 * ReaScript Name: Create a seamless loop with Split-Reverse Crossfade (with Offset)
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2024-12-11)
  + Initial Release
--]]

local item = reaper.GetSelectedMediaItem(0, 0)
if item == nil then
    return
end

reaper.Undo_BeginBlock()

local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
local item_mid = item_start + (item_length / 2)

reaper.SplitMediaItem(item, item_mid)

local item1 = reaper.GetSelectedMediaItem(0, 0)
local item2 = reaper.GetSelectedMediaItem(0, 1)

if item1 == nil or item2 == nil then
    reaper.Undo_EndBlock("Error - Failed to create loop", -1)
    return
end

local overlapping_factor = 0.05

local crossfade_length = item_length * overlapping_factor


local offset = 0.1 * crossfade_length
reaper.SetMediaItemInfo_Value(item2, "D_POSITION", item_start)
reaper.SetMediaItemInfo_Value(item1, "D_POSITION", item_mid - crossfade_length - offset)

reaper.SetMediaItemInfo_Value(item2, "D_FADEOUTLEN_AUTO", crossfade_length)
reaper.SetMediaItemInfo_Value(item1, "D_FADEINLEN_AUTO", crossfade_length)

reaper.SetMediaItemSelected(item1, true)
reaper.SetMediaItemSelected(item2, true)

reaper.Undo_EndBlock("Seamless loop creation", -1)

reaper.UpdateArrange()

