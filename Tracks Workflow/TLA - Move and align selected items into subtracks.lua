--[[
 * ReaScript Name: Move selected items into subtracks, aligned to first item's position per parent track
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
 * About:
  - Takes all selected items, groups them by parent track.
  - For each parent track:
      * Finds first selected item's position
      * Creates one subtrack per item
      * Moves each selected item into a different subtrack
      * Aligns items
  - Parent track becomes a folder
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-11-05)
  + Initial Release
--]]


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- helper : sort items by track
local items_by_track = {}

local count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items == 0 then
  reaper.ShowMessageBox("No items selected", "Error", 0)
  return
end

for i = 0, count_sel_items - 1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local track = reaper.GetMediaItem_Track(item)
  if not items_by_track[track] then items_by_track[track] = {} end
  table.insert(items_by_track[track], item)
end

-- iterate each track group
for track, items in pairs(items_by_track) do
  -- sort by position
  table.sort(items, function(a, b)
    return reaper.GetMediaItemInfo_Value(a, "D_POSITION") < reaper.GetMediaItemInfo_Value(b, "D_POSITION")
  end)

  local ref_pos = reaper.GetMediaItemInfo_Value(items[1], "D_POSITION")
  local parent_index = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
  local num_items = #items

  -- create subtracks
  for i = 1, num_items do
    reaper.InsertTrackAtIndex(parent_index + i, true)
    local child_track = reaper.GetTrack(0, parent_index + i)

    -- set as child track
    reaper.SetMediaTrackInfo_Value(child_track, "I_FOLDERDEPTH", 0)
  end

  -- set parent as folder start
  reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)

  -- set last subtrack folder end
  local last_child = reaper.GetTrack(0, parent_index + num_items)
  reaper.SetMediaTrackInfo_Value(last_child, "I_FOLDERDEPTH", -1)

  -- move items to subtracks + align to ref_pos
  for i, item in ipairs(items) do
    local child_track = reaper.GetTrack(0, parent_index + i)
    reaper.MoveMediaItemToTrack(item, child_track)
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", ref_pos)
  end
end

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Move selected items into subtracks (aligned to first item)", -1)
    