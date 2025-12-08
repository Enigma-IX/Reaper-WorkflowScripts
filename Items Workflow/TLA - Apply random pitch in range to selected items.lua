--[[
 * ReaScript Name: Apply random pitch in cents to selected items
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-18)
  + Initial Release
--]]

retval, user_input = reaper.GetUserInputs("Random pitch (cents)", 2, "Pitch min (cents),Pitch max (cents)", "-50,50")

if retval then
    min_str, max_str = user_input:match("([^,]+),([^,]+)")
    min_cents = tonumber(min_str)
    max_cents = tonumber(max_str)

    if not (min_cents and max_cents) then
        reaper.ShowMessageBox("Invalid values.", "Error", 0)
        return
    end

    if min_cents > max_cents then
        min_cents, max_cents = max_cents, min_cents
    end

    reaper.Undo_BeginBlock()

    item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No selected items.", "Error", 0)
        return
    end

    for i = 0, item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetActiveTake(item)
        if take ~= nil then
            rand_cents = min_cents + math.random() * (max_cents - min_cents)
            rand_pitch = rand_cents / 100.0
            reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", rand_pitch)
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Random pitch beteween "..min_cents.." & "..max_cents.." cents", -1)
end
