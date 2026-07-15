local feedPath = nil
local lastFeed = nil
local records = {}
local page = 1
local pageSize = 3

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
    local restoreAction = '["powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "#@#Scripts\\Restore-StowedApplication.ps1" -Handle ' .. handle .. ']'

    SKIN:Bang('!SetOption', 'MeterStowageLabel' .. suffix, 'Text', label)
    SKIN:Bang('!SetOption', 'MeterStowageTitle' .. suffix, 'Text', title)
    SKIN:Bang('!SetOption', 'MeterStowageCard' .. suffix, 'LeftMouseUpAction', restoreAction)
    SKIN:Bang('!SetOption', 'MeterStowageLabel' .. suffix, 'LeftMouseUpAction', restoreAction)
    SKIN:Bang('!SetOption', 'MeterStowageTitle' .. suffix, 'LeftMouseUpAction', restoreAction)
    SKIN:Bang('!SetOption', 'MeterStowageState' .. suffix, 'LeftMouseUpAction', restoreAction)
    SKIN:Bang('!ShowMeter', 'MeterStowageCard' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageLabel' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageTitle' .. suffix)
    SKIN:Bang('!ShowMeter', 'MeterStowageState' .. suffix)
end

local function parseFeed(feed)
    records = {}

    for record in feed:gmatch('[^/]+') do
        local number, label, title, handle = record:match('%s*(%d+)%s+([^|]+)%s*|%s*([^|]+)%s*|%s*H:(%d+)')
        if number and label and title and handle then
            table.insert(records, {
                number = tonumber(number),
                label = trim(label),
                title = trim(title),
                handle = handle
            })
        end
    end
end

local function renderPage()
    for index = 1, pageSize do hideSlot(index) end

    local count = #records
    if count == 0 then
        page = 1
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'Text', 'APPLICATION STOWAGE')
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'ToolTipText', '')
        SKIN:Bang('!SetOption', 'MeterStowageEmpty', 'Text', 'NO APPLICATIONS STOWED')
        SKIN:Bang('!ShowMeter', 'MeterStowageEmpty')
        SKIN:Bang('!UpdateMeterGroup', 'Stowage')
        SKIN:Bang('!Redraw')
        return 0
    end

    local pageCount = math.ceil(count / pageSize)
    if page > pageCount then page = 1 end

    local first = ((page - 1) * pageSize) + 1
    local last = math.min(first + pageSize - 1, count)

    SKIN:Bang('!HideMeter', 'MeterStowageEmpty')

    if pageCount > 1 then
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'Text', string.format('APPLICATION STOWAGE  %02d-%02d OF %02d', first, last, count))
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'ToolTipText', 'Select heading to view the next group of stowed applications.')
    else
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'Text', string.format('APPLICATION STOWAGE  %02d STORED', count))
        SKIN:Bang('!SetOption', 'MeterStowageHeading', 'ToolTipText', '')
    end

    local slot = 1
    for recordIndex = first, last do
        local record = records[recordIndex]
        showSlot(slot, record.label, record.title, record.handle)
        slot = slot + 1
    end

    SKIN:Bang('!UpdateMeterGroup', 'Stowage')
    SKIN:Bang('!Redraw')
    return last - first + 1
end

function Initialize()
    local localAppData = os.getenv('LOCALAPPDATA') or ''
    feedPath = localAppData .. '\\REOS\\stowage.txt'
    SKIN:Bang('!SetOption', 'MeterStowageHeading', 'LeftMouseUpAction', '[!CommandMeasure MeasureStowageCards "NextPage()"]')
end

function NextPage()
    local count = #records
    if count <= pageSize then
        return renderPage()
    end

    local pageCount = math.ceil(count / pageSize)
    page = page + 1
    if page > pageCount then page = 1 end
    return renderPage()
end

function Update()
    local file = io.open(feedPath, 'r')
    local feed = file and file:read('*a') or ''
    if file then file:close() end

    if feed ~= lastFeed then
        lastFeed = feed
        page = 1

        if feed == '' or feed:find('NO APPLICATIONS STOWED', 1, true) then
            records = {}
        else
            parseFeed(feed)
        end
    end

    return renderPage()
end
