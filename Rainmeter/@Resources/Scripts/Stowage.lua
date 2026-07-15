local slots = 6

function Initialize()
    ClearSlots()
end

function Update()
    local measure = SKIN:GetMeasure('MeasureWindowList')
    if not measure then return 0 end

    local output = measure:GetStringValue() or ''
    ClearSlots()

    local count = 0
    for line in output:gmatch('[^\r\n]+') do
        local slot, handle, title = line:match('^(%d+)|(%d+)|(.+)$')
        slot = tonumber(slot)
        if slot and slot >= 1 and slot <= slots then
            count = count + 1
            title = CondenseTitle(title)
            SKIN:Bang('!SetVariable', 'Slot' .. slot .. 'Handle', handle)
            SKIN:Bang('!SetVariable', 'Slot' .. slot .. 'Title', title)
            SKIN:Bang('!SetOption', 'MeterSlot' .. slot, 'Hidden', '0')
            SKIN:Bang('!SetOption', 'MeterSlot' .. slot .. 'Index', 'Hidden', '0')
            SKIN:Bang('!SetOption', 'MeterSlot' .. slot .. 'Lamp', 'Hidden', '0')
        end
    end

    if count == 0 then
        SKIN:Bang('!SetOption', 'MeterEmpty', 'Hidden', '0')
    else
        SKIN:Bang('!SetOption', 'MeterEmpty', 'Hidden', '1')
    end

    SKIN:Bang('!UpdateMeterGroup', 'Stowage')
    SKIN:Bang('!Redraw')
    return count
end

function ClearSlots()
    for i = 1, slots do
        SKIN:Bang('!SetVariable', 'Slot' .. i .. 'Handle', '0')
        SKIN:Bang('!SetVariable', 'Slot' .. i .. 'Title', '')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i, 'Hidden', '1')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Index', 'Hidden', '1')
        SKIN:Bang('!SetOption', 'MeterSlot' .. i .. 'Lamp', 'Hidden', '1')
    end
end

function CondenseTitle(title)
    title = title:gsub('%s+', ' ')
    if #title > 27 then
        return title:sub(1, 26) .. '…'
    end
    return title
end
