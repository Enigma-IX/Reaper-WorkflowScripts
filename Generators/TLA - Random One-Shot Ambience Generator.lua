--[[
 * ReaScript Name: Random Ambience Generator by Duration & Population
 * Author: Loris Tessier
 * REAPER: 7.5
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2025-08-19)
  + Initial Release
--]]

-- Config
local DEFAULT_CONFIG = {
  duration = 30.0,        -- Duration in seconds
  population = 50,        -- Population density (0-100%)
  volume_variation = 20,  -- Volume variation (0-100%)
  pitch_variation = 100,  -- Pitch variation (cents)
  pan_variation = 80,     -- Pan variation (0-100%)
  fade_duration = 0.02    -- Fades
}

-- Utils
local function random_float(min, max)
  return min + (max - min) * math.random()
end

local function clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

local function validate_input(input_str)
  local values = {}
  local i = 1
  for value in input_str:gmatch("([^,]+)") do
    values[i] = tonumber(value)
    if not values[i] then
      return nil, "invalid value: " .. tostring(value)
    end
    i = i + 1
  end
  
  if #values ~= 5 then
    return nil, "Missing arguments (needed: 5)"
  end
  
  local duration, population, vol_var, pitch_var, pan_var = table.unpack(values)
  
  -- Validations
  if duration <= 0 or duration > 3600 then
    return nil, "Duration should be between 0.1 and 3600 seconds"
  end
  if population < 0 or population > 100 then
    return nil, "Population should be between 0 and 100%"
  end
  if vol_var < 0 or vol_var > 100 then
    return nil, "Volume variation should be between 0 and 100%"
  end
  if pitch_var < 0 or pitch_var > 1200 then
    return nil, "Pitch variation should be between 0 and 1200 cents"
  end
  if pan_var < 0 or pan_var > 100 then
    return nil, "Pan variation should be between 0 and 100%"
  end
  
  return {
    duration = duration,
    population = population,
    volume_variation = vol_var,
    pitch_variation = pitch_var,
    pan_variation = pan_var
  }
end

-- UI
local function get_user_input()
  local default_input = string.format("%.1f,%.0f,%.0f,%.0f,%.0f",
    DEFAULT_CONFIG.duration,
    DEFAULT_CONFIG.population,
    DEFAULT_CONFIG.volume_variation,
    DEFAULT_CONFIG.pitch_variation,
    DEFAULT_CONFIG.pan_variation
  )
  
  local ret, user_input = reaper.GetUserInputs(
    "Ambiance Generator - Duration & Population",
    5,
    "Total Duration (s),Population (0-100%),Vol variation (%),Pitch variation (cents),Pan variation (%)",
    default_input
  )
  
  if not ret then return nil end
  
  local config, error_msg = validate_input(user_input)
  if not config then
    reaper.ShowMessageBox("Error: " .. error_msg, "Invalid arguments", 0)
    return nil
  end
  
  return config
end

local function collect_source_items()
  local item_count = reaper.CountSelectedMediaItems(0)
  if item_count == 0 then
    reaper.ShowMessageBox("Select at least one item.", "Empty selection", 0)
    return nil
  end
  
  local items = {}
  for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    
    if take then
      local source = reaper.GetMediaItemTake_Source(take)
      if source then
        table.insert(items, {
          source = source,
          length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH"),
          original_volume = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL"),
          original_pitch = reaper.GetMediaItemTakeInfo_Value(take, "D_PITCH"),
          original_pan = reaper.GetMediaItemTakeInfo_Value(take, "D_PAN")
        })
      end
    end
  end
  
  if #items == 0 then
    reaper.ShowMessageBox("No valid audio take in current selection.", "Error", 0)
    return nil
  end
  
  return items
end

local function create_ambience_track()
  local track_count = reaper.CountTracks(0)
  reaper.InsertTrackAtIndex(track_count, false)
  local new_track = reaper.GetTrack(0, track_count)
  
  reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", "Ambiance Generated", true)
  
  reaper.SetTrackColor(new_track, reaper.ColorToNative(100, 150, 200)|0x1000000)
  
  return new_track
end

local function generate_time_positions(duration, population, num_sources)
  local positions = {}

  local base_interval = 1.0
  local density_factor = (population / 100) * 4 + 0.1
  
  local approx_events = math.floor((duration / base_interval) * density_factor)
  approx_events = math.max(1, math.min(approx_events, duration * 2))
  
  for i = 1, approx_events do
    local position = random_float(0, duration * 0.95)
    table.insert(positions, position)
  end
  
  table.sort(positions)
  
  local min_gap = 0.1
  for i = 2, #positions do
    if positions[i] - positions[i-1] < min_gap then
      positions[i] = positions[i-1] + min_gap + random_float(0, 0.2)
    end
  end
  
  local filtered_positions = {}
  for _, pos in ipairs(positions) do
    if pos <= duration then
      table.insert(filtered_positions, pos)
    end
  end
  
  return filtered_positions
end

local function apply_variations(take, source_item, config)
  -- Volume
  if config.volume_variation > 0 then
    local vol_factor = 1 + random_float(-config.volume_variation/100, config.volume_variation/100)
    vol_factor = clamp(vol_factor, 0.1, 3.0)
    reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", source_item.original_volume * vol_factor)
  end
  
  -- Pitch
  if config.pitch_variation > 0 then
    local pitch_change = random_float(-config.pitch_variation, config.pitch_variation) / 100
    local new_pitch = clamp(source_item.original_pitch + pitch_change, -2.0, 2.0)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PITCH", new_pitch)
  end
  
  -- Pan
  if config.pan_variation > 0 then
    local pan_change = random_float(-config.pan_variation/100, config.pan_variation/100)
    local new_pan = clamp(source_item.original_pan + pan_change, -1.0, 1.0)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PAN", new_pan)
  end
end

local function create_ambience_item(track, source_item, position, config)
  local item = reaper.AddMediaItemToTrack(track)
  
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", source_item.length)
  
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", DEFAULT_CONFIG.fade_duration)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", DEFAULT_CONFIG.fade_duration)
  
  local take = reaper.AddTakeToMediaItem(item)
  reaper.SetMediaItemTake_Source(take, source_item.source)
  reaper.SetActiveTake(take)
  
  apply_variations(take, source_item, config)
  
  return item
end

local function main()
  local config = get_user_input()
  if not config then return end
  
  local source_items = collect_source_items()
  if not source_items then return end
  
  local start_position = reaper.GetCursorPosition()
  
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  
  local ambience_track = create_ambience_track()
  
  local positions = generate_time_positions(config.duration, config.population, #source_items)
  
  local created_items = {}
  for _, relative_pos in ipairs(positions) do
    local absolute_pos = start_position + relative_pos
    
    local source_item = source_items[math.random(1, #source_items)]
    
    local new_item = create_ambience_item(ambience_track, source_item, absolute_pos, config)
    table.insert(created_items, new_item)
  end
  
  reaper.SelectAllMediaItems(0, false)
  for _, item in ipairs(created_items) do
    reaper.SetMediaItemSelected(item, true)
  end
  
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Generate Ambience by Duration & Population", -1)
  
  local message = string.format(
    "Ambiance generated with success!\n\n" ..
    "• Duration: %.1f seconds\n" ..
    "• Population: %.0f%%\n" ..
    "• Created items: %d\n" ..
    "• Used sources: %d\n" ..
    "• New track: 'Ambiance Generated'",
    config.duration,
    config.population,
    #created_items,
    #source_items
  )
  
  reaper.ShowMessageBox(message, "Generation done", 0)
end

math.randomseed(os.time())

main()