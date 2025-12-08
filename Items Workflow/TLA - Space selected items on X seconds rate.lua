--[[
 * ReaScript Name: Space selected items on X seconds rate
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-18)
  + Initial Release
--]]

retval, user_input = reaper.GetUserInputs("Spacing items (start-to-start)", 1, "Spacing (seconds)", "1.0")

if retval then
    spacing = tonumber(user_input)
    if spacing == nil then
        reaper.ShowMessageBox("Invalid value.", "Error", 0)
        return
    end

    reaper.Undo_BeginBlock()

    item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No items selected.", "Error", 0)
        return
    end

    items = {}
    for i = 0, item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        table.insert(items, {item=item, pos=pos})
    end
    table.sort(items, function(a,b) return a.pos < b.pos end)

    start_pos = items[1].pos
    for i = 1, #items do
        new_pos = start_pos + (i-1) * spacing
        reaper.SetMediaItemInfo_Value(items[i].item, "D_POSITION", new_pos)
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Space selected items (start-to-start) to "..spacing.."s rate", -1)
end
