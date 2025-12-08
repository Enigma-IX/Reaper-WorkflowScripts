--[[
 * ReaScript Name: Create a single parent Track for selected Tracks
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-01-07)
  + Initial Release
--]]

local num_selected_tracks = reaper.CountSelectedTracks(0)
if num_selected_tracks == 0 then
    return
end

reaper.Undo_BeginBlock()

local first_selected_track = reaper.GetSelectedTrack(0, 0)
local first_track_index = reaper.GetMediaTrackInfo_Value(first_selected_track, "IP_TRACKNUMBER") - 1

reaper.InsertTrackAtIndex(first_track_index, true)
local parent_track = reaper.GetTrack(0, first_track_index)

reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERDEPTH", 1)  -- Parent track

for i = 0, num_selected_tracks - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    if track then
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)  -- Child track
    end
end

local last_selected_track = reaper.GetSelectedTrack(0, num_selected_tracks - 1)
if last_selected_track then
    reaper.SetMediaTrackInfo_Value(last_selected_track, "I_FOLDERDEPTH", -1)  -- End folder
end

reaper.Undo_EndBlock("Create a single parent Track for selected Tracks", -1)

