--[[
 * ReaScript Name: Swap selected items randomly
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-18)
  + Initial Release
--]]

reaper.Undo_BeginBlock()

local item_count = reaper.CountSelectedMediaItems(0)

if item_count < 2 then
    reaper.ShowMessageBox("Select more than 1 items to swap them.", "Error", 0)
    return
end

local positions = {}
for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    table.insert(positions, pos)
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

shuffle(positions)

for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", positions[i + 1])
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Swap selected items positions", -1)
