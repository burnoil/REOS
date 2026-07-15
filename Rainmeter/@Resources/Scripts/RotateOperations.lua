local records = {}
local index = 0
local tick = 0
local interval = 45

local function trim(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function loadFeed()
    records = {}
    local path = SKIN:GetVariable('@') .. 'Data\\OperationsFeed.inc'
    local file = io.open(path, 'r')
    if not file then return end

    local values = {}
    for line in file:lines() do
        local key, value = line:match('^([%w]+)%s*=%s*(.*)$')
        if key and value then values[key] = trim(value) end
    end
    file:close()

    local count = tonumber(values.FeedCount or '0') or 0
    for i = 1, count do
        table.insert(records, {
            time = values['Feed' .. i .. 'Time'] or '--:--',
            source = values['Feed' .. i .. 'Source'] or 'OPERATIONS',
            title = values['Feed' .. i .. 'Title'] or 'NO RECORD AVAILABLE',
            reference = values['Feed' .. i .. 'Ref'] or 'UNASSIGNED',
            state = values['Feed' .. i .. 'State'] or 'AVAILABLE'
        })
    end
end

local function applyRecord()
    if #records == 0 then return end
    local record = records[index]
    SKIN:Bang('!SetVariable', 'CurrentFeedTime', record.time)
    SKIN:Bang('!SetVariable', 'CurrentFeedSource', record.source)
    SKIN:Bang('!SetVariable', 'CurrentFeedTitle', record.title)
    SKIN:Bang('!SetVariable', 'CurrentFeedRef', record.reference)
    SKIN:Bang('!SetVariable', 'CurrentFeedState', record.state)
    SKIN:Bang('!UpdateMeterGroup', 'Feed')
    SKIN:Bang('!Redraw')
end

function Initialize()
    loadFeed()
    index = 1
    tick = 0
    applyRecord()
end

function Update()
    tick = tick + 1
    if tick >= interval then
        tick = 0
        if #records > 0 then
            index = index + 1
            if index > #records then index = 1 end
            applyRecord()
        end
    end
    return index
end
