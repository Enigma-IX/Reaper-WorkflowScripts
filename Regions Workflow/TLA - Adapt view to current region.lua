--[[
 * ReaScript Name: Adapt view to current region
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-03-13)
  + Initial Release
--]]

function ZoomToCurrentRegion()
    local play_pos = reaper.GetCursorPosition()
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)

    local offset_start = 0.3
    local offset_end_1 = 10
    local offset_end_2 = 1
    local epsilon = 1.0  -- tolerance

    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, region_start, region_end, _, _ = reaper.EnumProjectMarkers(i)

        local start_view, end_view = reaper.GetSet_ArrangeView2(0, false, 0, 0)

        if is_region and play_pos >= region_start and play_pos <= region_end then
            local expected_start = region_start - offset_start
            local expected_end_1 = region_end + offset_end_1
            local expected_end_2 = region_end + offset_end_2

            local is_on_offset_10 = (end_view >= expected_end_2 - epsilon) and (end_view <= expected_end_2 + epsilon)

            local new_offset_end = is_on_offset_10 and offset_end_1 or offset_end_2
            local new_expected_end = region_end + new_offset_end
            reaper.GetSet_ArrangeView2(0, true, 0, 0, expected_start, new_expected_end)
            reaper.UpdateArrange()
            
            return
        end
    end
end

ZoomToCurrentRegion()

