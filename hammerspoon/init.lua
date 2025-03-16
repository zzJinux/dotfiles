local logger = hs.logger.new('init.lua', 'info')

local function setupInputSourceChanger()
  local inputSource = {
    english = "com.apple.keylayout.ABC",
    korean = "com.apple.inputmethod.Korean.2SetKorean",
  }

  local changeInput = function()
    local current = hs.keycodes.currentSourceID()
    local nextInput = nil

    if current ~= inputSource.korean then
      nextInput = inputSource.korean
    else
      nextInput = inputSource.english
    end
    hs.keycodes.currentSourceID(nextInput)
  end

  hs.hotkey.bind({}, 'F15', changeInput)
end

local function escape(s)
  return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]', '%%%1'))
end

local function Rule(prefixes, processor)
  local rule = {
    prefixes = prefixes,
    processor = processor
  }

  function rule:match(fullURL)
    for _, prefix in ipairs(self.prefixes) do
      if string.match(fullURL, '^https?://' .. escape(prefix)) or
        string.match(fullURL, '^https?://[^/]+%.' .. escape(prefix)) then
        return prefix
      end
    end
    return ''
  end

  return rule
end

URLRouterPicky = false
function ToggleURLRouterPicky()
  URLRouterPicky = not URLRouterPicky
end

function setupURLRouter(config)
  local processors = {}
  local procNames = {}

  for _, browser in ipairs(config["browsers"]) do
    local name = browser["name"]
    local command = browser["cmd"][1]
    local arguments = { table.unpack(browser["cmd"], 2) }

    processors[name] = function(fullURL)
      local arguments = { table.unpack(arguments) }
      table.insert(arguments, fullURL)
      local task = hs.task.new(command, nil, function() return false end, arguments)
      task:start()
    end

    table.insert(procNames, name)
  end

  processors["copy"] = function(fullURL)
    local success = hs.pasteboard.setContents(fullURL)

    if success then
      logger.i("URL copied to pasteboard: " .. fullURL)
    else
      logger.e("Error: Failed to copy URL to pasteboard: " .. fullURL)
    end
  end

  table.insert(procNames, "copy")

  local applescriptSource = 'choose from list ' .. hs.inspect(procNames) ..
      ' with prompt "Open URL with…"'

  processors["picker"] = function(fullURL)
    local success, osaObj, _ = hs.osascript.applescript(applescriptSource)

    local choice = osaObj[1]
    if success and choice then
      local processor = processors[choice]

      if processor then
        processor(fullURL)
      else
        logger.e("Error: Processor not found for " .. tostring(choice))
      end
    end
  end

  local rules = {}
  for _, ruleData in ipairs(config["rules"]) do
    local rule = Rule(ruleData["prefixes"], ruleData["processor"])
    table.insert(rules, rule)
  end

  local default = config["default"]

  local function processURL(url)
    local procName
    if URLRouterPicky then
      procName = "picker"
    else
      local maxlen = 0
      for _, rule in ipairs(rules) do
        local d = rule:match(url)
        if #d > maxlen then
          maxlen = #d
          procName = rule.processor
        end
      end
    end

    procName = procName or default
    local processor = processors[procName]
    
    if processor then
      processor(url)
    else
      logger.e("Error: Processor not found for " .. tostring(procName))
    end
  end

  hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    logger.i("URL opened: " .. fullURL)

    if fullURL == nil then
      -- DO NOTHING
      return
    end

    -- Check if localhost/127.0.0.* and follow redirects
    if host == "localhost" or string.match(host, "^127%.%d+%.%d+%.%d+$") then
      hs.http.doAsyncRequest(fullURL, "GET", nil, nil, function(status, body, headers)
        local finalURL = fullURL
        if status and status >= 300 and status < 400 and headers["Location"] then
          finalURL = headers["Location"]
          logger.i("Following redirect to: " .. finalURL)
        end
        
        processURL(finalURL)
      end, false)
      return
    end

    processURL(fullURL)
  end
end

do
  hs.console.printStyledtext("LOG LELVEL: " .. tostring(logger.getLogLevel()))

  setupInputSourceChanger()

  local config = hs.json.read(hs.configdir .. "/" .. "url_router.json")
  if config then
    setupURLRouter(config)
  end
end

if hs.fs.attributes(hs.configdir .. "/" .. "init_private.lua") then
  require("init_private")
end
