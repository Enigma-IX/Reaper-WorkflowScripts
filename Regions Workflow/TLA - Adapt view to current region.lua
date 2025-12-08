--[[
 * ReaScript Name: Adapt view to current region (Toggle)
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 2.0
--]]
 
--[[
 * Changelog:
 * v2.0 (2025-12-08)
  + Complete rewrite: True toggle ON/OFF with view memory
 * v1.1 (2025-12-08)
  + Modified offsets to use percentages of region length
 * v1.0 (2025-03-13)
  + Initial Release
--]]

function ZoomToCurrentRegion()
    local play_pos = reaper.GetCursorPosition()
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    
    local offset_start_percent = 5
    local offset_end_percent = 5
    
    local epsilon_percent = 2
    
    for i = 0, num_markers + num_regions - 1 do
        local _, is_region, region_start, region_end, _, _ = reaper.EnumProjectMarkers(i)
        
        if is_region and play_pos >= region_start and play_pos <= region_end then
            local region_length = region_end - region_start
            
            local offset_start = region_length * (offset_start_percent / 100)
            local offset_end = region_length * (offset_end_percent / 100)
            local epsilon = region_length * (epsilon_percent / 100)
            
            local expected_start = region_start - offset_start
            local expected_end = region_end + offset_end
            
            local current_start, current_end = reaper.GetSet_ArrangeView2(0, false, 0, 0)
            
            local is_zoomed = math.abs(current_start - expected_start) < epsilon and 
                              math.abs(current_end - expected_end) < epsilon
            
            if is_zoomed then
                local prev_start = reaper.GetExtState("RegionZoom", "prev_start")
                local prev_end = reaper.GetExtState("RegionZoom", "prev_end")
                
                if prev_start ~= "" and prev_end ~= "" then
                    reaper.GetSet_ArrangeView2(0, true, 0, 0, tonumber(prev_start), tonumber(prev_end))
                    reaper.SetExtState("RegionZoom", "prev_start", "", false)
                    reaper.SetExtState("RegionZoom", "prev_end", "", false)
                end
            else
                reaper.SetExtState("RegionZoom", "prev_start", tostring(current_start), false)
                reaper.SetExtState("RegionZoom", "prev_end", tostring(current_end), false)
                reaper.GetSet_ArrangeView2(0, true, 0, 0, expected_start, expected_end)
            end
            
            reaper.UpdateArrange()
            return
        end
    end
end

ZoomToCurrentRegion()

