--[[
 * ReaScript Name: Space selected items by X seconds
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-18)
  + Initial Release
--]]

retval, user_input = reaper.GetUserInputs("Spacing items", 1, "Spacing (seconds)", "0.5")

if retval then
    spacing = tonumber(user_input)
    if spacing == nil then
        reaper.ShowMessageBox("Invalid Value.", "Error", 0)
        return
    end

    reaper.Undo_BeginBlock()

    item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No items selected", "Error", 0)
        return
    end

    items = {}
    for i = 0, item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        table.insert(items, {item=item, pos=pos})
    end
    table.sort(items, function(a,b) return a.pos < b.pos end)

    cur_pos = items[1].pos
    for i = 1, #items do
        reaper.SetMediaItemInfo_Value(items[i].item, "D_POSITION", cur_pos)
        length = reaper.GetMediaItemInfo_Value(items[i].item, "D_LENGTH")
        cur_pos = cur_pos + length + spacing
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Space selected items by "..spacing.."s", -1)
end
