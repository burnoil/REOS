local feedPath = nil
local lastFeed = nil

local function trim(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function hideSlot(index)
    SKIN:Bang('!HideMeter', 'MeterStowageCard' .. index)
    SKIN:Bang('!HideMeter', 'MeterStowageLabel' .. index)
    SKIN:Bang('!HideMeter', 'MeterStowageTitle' .. index)
    SKIN:Bang('!HideMeter', 'MeterStowageState' .. index)
end

local function showSlot(index, label, title, handle)
    local suffix = tostring(index)
    SKIN:Bang('!SetOption', 'MeterStowageLabel' .. suffix, 'Text', label)
    SKIN:Bang('!SetOption', 'MeterStowageTitle' .. suffix, 'Text', title)
    SKIN:Bang('!SetOption', 'MeterStowageCard' .. suffix, 'LeftMouseUpAction', '["powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#@#Scripts\\Restore-StowedApplication.ps1" -Handle ' .. handle .. ']')
    SKIN:Bang('!SetOption', 'MeterStowageLabel' .. suffix, 'LeftMouseUpAction', '["powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#@#Scripts\\Restore-StowedApplication.ps1" -Handle ' .. handle .. ']')
    SKIN:Bang('!SetOption', 'MeterStowageTitle' .. suffix, 'LeftMouseUpAction', '["powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#@#Scripts\\Restore-StowedApplication.ps1" -Handle ' .. handle .. ']')
    SKIN:Bang('!SetOption', 'MeterStowageState' .. suffix, 'LeftMouseUpAction', '["powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#@#Scripts\\Restore-StowedApplication.ps1" -Handle ' .. handle .. ']')
    SKIN:Bang('!ShowMeter', 'MeterStowageCard' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageLabel' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageTitle' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageState' .. suffix)
end

function Initialize()
    local localAppData = os.getenv('LOCALAPPDATA') or ''
    feedPath = localAppData .. '\\REOS\\stowage.txt'
end

function Update()
    local file = io.open(feedPath, 'r')
    local feed = file and file:read('*a') or ''
    if file then file:close() end

    if feed == lastFeed then
        return 0
    end
    lastFeed = feed

    for index = 1, 3 do hideSlot(index) end

    if feed == '' or feed:find('NO APPLICATIONS STOWED', 1, true) then
        SKIN:Bang('!SetOption', 'MeterStowageEmpty', 'Text', 'NO APPLICATIONS STOWED')
        SKIN:Bang('!ShowMeter', 'MeterStowageEmpty')
        SKIN:Bang('!UpdateMeterGroup', 'Stowage')
        SKIN:Bang('!Redraw')
        return 0
    end

    SKIN:Bang('!HideMeter', 'MeterStowageEmpty')
    local slot = 1
    for record in feed:gmatch('[^/]+') do
        if slot > 3 then break end
        local number, label, title, handle = record:match('%s*(%d+)%s+([^|]+)%s*|%s*([^|]+)%s*|%s*H:(%d+)')
        if number and label and title and handle then
            showSlot(slot, trim(label), trim(title), handle)
            slot = slot + 1
        end
    end

    SKIN:Bang('!UpdateMeterGroup', 'Stowage')
    SKIN:Bang('!Redraw')
    return slot - 1
end
