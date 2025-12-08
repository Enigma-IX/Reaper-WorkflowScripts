--[[
 * ReaScript Name: Snap selected items to start of containing region
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-11-10)
  + Initial Release
--]]

function Msg(val)
  reaper.ShowConsoleMsg(tostring(val) .. "\n")
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local num_items = reaper.CountSelectedMediaItems(0)
if num_items == 0 then
  reaper.MB("No items selected", "Error", 0)
  return
end

local marker_idx = 0
local num_markers, num_regions = reaper.CountProjectMarkers(0)
local regions = {}

for i = 0, num_markers + num_regions - 1 do
  local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
  if isrgn then
    table.insert(regions, {start = pos, ending = rgnend, name = name})
  end
end

function GetRegionAtTime(time)
  for i, r in ipairs(regions) do
    if time >= r.start and time < r.ending then
      return r.start
    end
  end
  return nil
end

for i = 0, num_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

  local region_start = GetRegionAtTime(pos)
  if region_start ~= nil then
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", region_start)
  end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Snap selected items to start of containing region", -1)
