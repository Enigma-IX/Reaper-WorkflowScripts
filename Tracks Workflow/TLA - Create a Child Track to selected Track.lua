--[[
 * ReaScript Name: Create a single child Track for selected Tracks
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-01-07)
  + Initial Release
--]]

preserve_track_name = false
suffix = "" -- suffix or new name if preserve_track_name is false

------------- END OF USER CONFIG AREA

function main()

  reaper.Undo_BeginBlock()

  for i = reaper.CountTracks(0)- 1, 0, -1 do
    track = reaper.GetTrack(0, i)
    id = reaper.CSurf_TrackToID(track, false)
    depth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

    found = reaper.IsTrackSelected(track)

    if found == true then
    reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
      reaper.InsertTrackAtIndex(id,true)
      next_track = reaper.GetTrack(0, id)
      retval, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
      if preserve_track_name then
        new_name = track_name .. suffix
      else
        new_name = suffix
      end
      reaper.GetSetMediaTrackInfo_String(next_track, "P_NAME", new_name, true)
      id = id +1
      i = i+1

    end

    if found == true and depth ~= 1 then
      depth = depth - 1
      reaper.SetMediaTrackInfo_Value(reaper.CSurf_TrackFromID(id, false),"I_FOLDERDEPTH",depth)
      depth = 1
      reaper.SetMediaTrackInfo_Value(track,"I_FOLDERDEPTH",depth)
    end
  end

  reaper.Undo_EndBlock("Insert one new child track for each selected tracks", 0)

end


reaper.PreventUIRefresh(1)

main()

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()
