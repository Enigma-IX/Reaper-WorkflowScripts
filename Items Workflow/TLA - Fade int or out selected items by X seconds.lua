--[[
 * ReaScript Name: Apply fade-in and fade-out to selected items
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-18)
  + Initial Release
--]]

retval, user_input = reaper.GetUserInputs("Fade in/out", 2, "Fade-in (sec, 0=aucun),Fade-out (sec, 0=aucun)", "0.5,1.0")

if retval then
    fadein_str, fadeout_str = user_input:match("([^,]+),([^,]+)")
    fadein = tonumber(fadein_str)
    fadeout = tonumber(fadeout_str)

    if not fadein or not fadeout or fadein < 0 or fadeout < 0 then
        reaper.ShowMessageBox("Invalid values.", "Error", 0)
        return
    end

    reaper.Undo_BeginBlock()

    item_count = reaper.CountSelectedMediaItems(0)
    if item_count == 0 then
        reaper.ShowMessageBox("No item selected.", "Error", 0)
        return
    end

    for i = 0, item_count-1 do
        item = reaper.GetSelectedMediaItem(0, i)

        if fadein > 0 then
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadein)
        end

        if fadeout > 0 then
            reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", fadeout)
        end
    end

    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Fade-in ("..fadein.."s) & Fade-out ("..fadeout.."s)", -1)
end
