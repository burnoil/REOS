function Initialize()
end

local function trim(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

function Parse(payload)
    if payload == nil or payload == '' then
        return
    end

    local values = {}
    for value in string.gmatch(payload, '([^|]+)') do
        table.insert(values, trim(value))
    end

    if #values < 5 then
        return
    end

    SKIN:Bang('!SetVariable', 'NetworkName', values[1] or 'LOCAL NETWORK')
    SKIN:Bang('!SetVariable', 'InterfaceName', values[2] or 'UNKNOWN')
    SKIN:Bang('!SetVariable', 'LinkType', values[3] or 'UNKNOWN')
    SKIN:Bang('!SetVariable', 'IPv4Address', values[4] or '---.---.---.---')
    SKIN:Bang('!SetVariable', 'Gateway', values[5] or '---.---.---.---')
    SKIN:Bang('!SetVariable', 'SignalText', values[6] or '')
    SKIN:Bang('!UpdateMeterGroup', '*')
    SKIN:Bang('!Redraw')
end
