function Initialize()
    local localAppData = os.getenv('LOCALAPPDATA') or ''
    feedPath = localAppData .. '\\REOS\\stowage.txt'
end

function Update()
    local file = io.open(feedPath, 'r')
    if not file then
        return 'REOS.CORE FEED NOT AVAILABLE'
    end

    local content = file:read('*a') or ''
    file:close()

    content = content:gsub('[\r\n]+', ' ')
    content = content:gsub('%s+', ' ')
    content = content:match('^%s*(.-)%s*$') or ''

    if content == '' then
        return 'NO APPLICATIONS STOWED'
    end

    return content
end
