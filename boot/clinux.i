print("Loading")
sleep(2)
CHANNEL_BROADCAST = 65535
CHANNEL_REPEAT = 65533

local tReceivedMessages = {}
local tReceivedMessageTimeouts = {}
local tHostnames = {}
rednet = {}
function rednet.open( sModem )
	if type( sModem ) ~= "string" then
		error( "expected string", 2 )
	end
	if peripheral.getType( sModem ) ~= "modem" then
		error( "No such modem: "..sModem, 2 )
	end
	peripheral.call( sModem, "open", os.getComputerID() )
	peripheral.call( sModem, "open", CHANNEL_BROADCAST )
end

function rednet.close( sModem )
    if sModem then
        -- Close a specific modem
        if type( sModem ) ~= "string" then
            error( "expected string", 2 )
        end
        if peripheral.getType( sModem ) ~= "modem" then
            error( "No such modem: "..sModem, 2 )
        end
        peripheral.call( sModem, "close", os.getComputerID() )
        peripheral.call( sModem, "close", CHANNEL_BROADCAST )
    else
        -- Close all modems
        for n,sModem in ipairs( peripheral.getNames() ) do
            if rednet.isOpen( sModem ) then
                close( sModem )
            end
        end
    end
end

function rednet.isOpen( sModem )
    if sModem then
        -- Check if a specific modem is open
        if type( sModem ) ~= "string" then
            error( "expected string", 2 )
        end
        if peripheral.getType( sModem ) == "modem" then
            return peripheral.call( sModem, "isOpen", os.getComputerID() ) and peripheral.call( sModem, "isOpen", CHANNEL_BROADCAST )
        end
    else
        -- Check if any modem is open
        for n,sModem in ipairs( peripheral.getNames() ) do
            if rednet.isOpen( sModem ) then
                return true
            end
        end
    end
	return false
end

function rednet.send( nRecipient, message, sProtocol )
    -- Generate a (probably) unique message ID
    -- We could do other things to guarantee uniqueness, but we really don't need to
    -- Store it to ensure we don't get our own messages back
    local nMessageID = math.random( 1, 2147483647 )
    tReceivedMessages[ nMessageID ] = true
    tReceivedMessageTimeouts[ os.startTimer( 30 ) ] = nMessageID

    -- Create the message
    local nReplyChannel = os.getComputerID()
    local tMessage = {
        nMessageID = nMessageID,
        nRecipient = nRecipient,
        message = message,
        sProtocol = sProtocol,
    }

    if nRecipient == os.getComputerID() then
        -- Loopback to ourselves
        os.queueEvent( "rednet_message", nReplyChannel, message, sProtocol )

    else
        -- Send on all open modems, to the target and to repeaters
        local sent = false
        for n,sModem in ipairs( peripheral.getNames() ) do
            if rednet.isOpen( sModem ) then
                peripheral.call( sModem, "transmit", nRecipient, nReplyChannel, tMessage );
                peripheral.call( sModem, "transmit", CHANNEL_REPEAT, nReplyChannel, tMessage );
                sent = true
            end
        end
    end
end

function rednet.broadcast( message, sProtocol )
	rednet.send( CHANNEL_BROADCAST, message, sProtocol )
end

function rednet.receive( sProtocolFilter, nTimeout )
    -- The parameters used to be ( nTimeout ), detect this case for backwards compatibility
    if type(sProtocolFilter) == "number" and nTimeout == nil then
        sProtocolFilter, nTimeout = nil, sProtocolFilter
    end

    -- Start the timer
	local timer = nil
	local sFilter = nil
	if nTimeout then
		timer = os.startTimer( nTimeout )
		sFilter = nil
	else
		sFilter = "rednet_message"
	end

	-- Wait for events
	while true do
		local sEvent, p1, p2, p3 = os.pullEvent( sFilter )
		if sEvent == "rednet_message" then
		    -- Return the first matching rednet_message
			local nSenderID, message, sProtocol = p1, p2, p3
			if sProtocolFilter == nil or sProtocol == sProtocolFilter then
    			return nSenderID, message, sProtocol
    	    end
		elseif sEvent == "timer" then
		    -- Return nil if we timeout
		    if p1 == timer then
    			return nil
    		end
		end
	end
end

function rednet.host( sProtocol, sHostname )
    if type( sProtocol ) ~= "string" or type( sHostname ) ~= "string" then
        error( "expected string, string", 2 )
    end
    if sHostname == "localhost" then
        error( "Reserved hostname", 2 )
    end
    if tHostnames[ sProtocol ] ~= sHostname then
        if rednet.lookup( sProtocol, sHostname ) ~= nil then
            error( "Hostname in use", 2 )
        end
        tHostnames[ sProtocol ] = sHostname
    end
end

function rednet.unhost( sProtocol )
    if type( sProtocol ) ~= "string" then
        error( "expected string", 2 )
    end
    tHostnames[ sProtocol ] = nil
end

function rednet.lookup( sProtocol, sHostname )
    if type( sProtocol ) ~= "string" then
        error( "expected string", 2 )
    end

    -- Build list of host IDs
    local tResults = nil
    if sHostname == nil then
        tResults = {}
    end

    -- Check localhost first
    if tHostnames[ sProtocol ] then
        if sHostname == nil then
            table.insert( tResults, os.getComputerID() )
        elseif sHostname == "localhost" or sHostname == tHostnames[ sProtocol ] then
            return os.getComputerID()
        end
    end

    if not rednet.isOpen() then
        if tResults then
            return table.unpack( tResults )
        end
        return nil
    end

    -- Broadcast a lookup packet
    rednet.broadcast( {
        sType = "lookup",
        sProtocol = sProtocol,
        sHostname = sHostname,
    }, "dns" )

    -- Start a timer
    local timer = os.startTimer( 2 )

    -- Wait for events
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        if event == "rednet_message" then
            -- Got a rednet message, check if it's the response to our request
            local nSenderID, tMessage, sMessageProtocol = p1, p2, p3
            if sMessageProtocol == "dns" and type(tMessage) == "table" and tMessage.sType == "lookup response" then
                if tMessage.sProtocol == sProtocol then
                    if sHostname == nil then
                        table.insert( tResults, nSenderID )
                    elseif tMessage.sHostname == sHostname then
                        return nSenderID
                    end
                end
            end
        else
            -- Got a timer event, check it's the end of our timeout
            if p1 == timer then
                break
            end
        end
    end
    if tResults then
        return table.unpack( tResults )
    end
    return nil
end

local bRunning = false
function rednet.run()
	if bRunning then
		error( "rednet is already running", 2 )
	end
	bRunning = true

	while bRunning do
		local sEvent, p1, p2, p3, p4 = os.pullEventRaw()
		if sEvent == "modem_message" then
			-- Got a modem message, process it and add it to the rednet event queue
    		local sModem, nChannel, nReplyChannel, tMessage = p1, p2, p3, p4
		    if rednet.isOpen( sModem ) and ( nChannel == os.getComputerID() or nChannel == CHANNEL_BROADCAST ) then
    			if type( tMessage ) == "table" and tMessage.nMessageID then
	    			if not tReceivedMessages[ tMessage.nMessageID ] then
		    			tReceivedMessages[ tMessage.nMessageID ] = true
                        tReceivedMessageTimeouts[ os.startTimer( 30 ) ] = nMessageID
			    		os.queueEvent( "rednet_message", nReplyChannel, tMessage.message, tMessage.sProtocol )
				    end
			    end
			end

		elseif sEvent == "rednet_message" then
		    -- Got a rednet message (queued from above), respond to dns lookup
		    local nSenderID, tMessage, sProtocol = p1, p2, p3
		    if sProtocol == "dns" and type(tMessage) == "table" and tMessage.sType == "lookup" then
		        local sHostname = tHostnames[ tMessage.sProtocol ]
		        if sHostname ~= nil and (tMessage.sHostname == nil or tMessage.sHostname == sHostname) then
		            rednet.send( nSenderID, {
		                sType = "lookup response",
		                sHostname = sHostname,
		                sProtocol = tMessage.sProtocol,
		            }, "dns" )
		        end
		    end

		elseif sEvent == "timer" then
            -- Got a timer event, use it to clear the event queue
            local nTimer = p1
            local nMessage = tReceivedMessageTimeouts[ nTimer ]
            if nMessage then
                tReceivedMessageTimeouts[ nTimer ] = nil
                tReceivedMessages[ nMessage ] = nil
            end
		end
	end
end




local bos = {}

for k, v in pairs(_G.os) do
	bos[k] = v
end

local tAPIsLoading = {}
function bos.loadAPI( _sPath )
    local sName = fs.getName( _sPath )
    if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath, tEnv )
    if fnAPI then
        local ok, err = pcall( fnAPI )
        if not ok then
            printError( err )
            tAPIsLoading[sName] = nil
            return false
        end
    else
        printError( err )
        tAPIsLoading[sName] = nil
        return false
    end

    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end
    tAPIsLoading[sName] = nil
    return true, _putLib(sName, tAPI), _put(sName, tAPI)
end

local oos = {}
for k, v in pairs(_G.os) do
    oos[k] = v
end

function bos.pullEvent(_filtr)
    if _filtr then
        repeat
            local evt = {oos.pullEventRaw()}
        until evt[1] == _filtr
        return unpack(evt)
    else
        return oos.pullEventRaw()
    end
end

function bos.pullEventRaw(_filtr)
    if _filtr then
        repeat
            local _, a, b, c = oos.pullEventRaw()
        until _ == _filtr
        return _, a, b, c
    else
        return oos.pullEventRaw()
    end
end

--[[
	cLinux : Lore of the Day!
	Made by Piorjade, daelvn

	NAME:        /boot/clinux.i
	CATEGORY:    boot
	SET:         Boot I
	VERSION:     01:alpha0
	DESCRIPTION:
		This script is ran after /startup and
		it sets flags manually, also loading
		some utils for posterior scripts.
]]--

function loadAPI(path)
	local ok, err = loadfile(path)
	if not ok then
		return false, err
	else
		local ok, err = ok()
		if ok == false then
			return false, err
		else
			return true
		end
	end
end

-- Put in _G
function _put(a,b) _G[a]=b end
local lib = {}

function _putLib(a,b) _G['lib'][a]=b end
_put('_put', _put)
_put('lib', lib)
_put('_putLib', _putLib)
_putLib('rednet', rednet)
_putLib('os', bos)
function _check(a)
	if _G[a] == nil then
		return false
	else
		return true
	end
end
_put('_check', _check)
-- Put in _G.flag
_put('flag', {})


local ok, err = loadAPI("/sys/thread.l")
if not ok then
	printError(err)
	return
end


function _flag(a,b) _G.flag[a] = b end
_put('_flag', _flag)
_put('loadAPI', loadAPI)
-- Get _G.flag[flag]
function _getflag(flag) return flag[flag] end
_put('_getflag', _getflag)
-- Loadfile, securely
_put('_REQUIRECACHE', {})
local function require(file)
	local function go()
		loadfile(file)
	end
	local ok, ret = pcall(go)
	if ok then
		_REQUIRECACHE[#_REQUIRECACHE+1] = file
		return true
	else
		return false
	end
end
local function cLinuxPrintError(status, message)
	local c = term.getTextColor()
	term.setTextColor(colors.red)
	print("["..tostring(status).."] "..tostring(message))
	term.setTextColor(c)
end

_put('cLinuxPrintError', cLinuxPrintError)
_put('require', require)
-- Set system flags
--- Debug level, set to 0 by default, use /startup
_flag('SYSDEBUG', 0)
-- Starting the OS, can't be changed
_flag('STATE_INIT', true)
-- Ignore the current services.conf, for example to start the commandline
_flag('text', false)



_arg = {...}
if #_arg > 0 then
	for _,arg in pairs(_arg) do
		if arg == "sysdebug" then
		    flag.SYSDEBUG = flag.SYSDEBUG + 1
		elseif arg == "rescue" then
			flag.RESCUE = true
		elseif arg == "text" then
			flag.text = true
		end
	end
end
-- Top Level Corroutine Override
local syserror = printError
_put('syserror', syserror)
_G.printError = function()
	_G.printError = syserror
	_G['rednet'] = nil
	print("Okay!")
	local evt = {}
		--initiate ground-environment
		local newenv = {}
		for k, v in pairs(_G) do
			newenv[k] = v
		end
		setmetatable(newenv, {})
		--initiate ground-tasklist
		local tasks = {}
		tasks['list'] = {}
		tasks['last_uid'] = 0
		tasks['somethingInFG'] = false



		print("loading core")
		local ok, err = thread.new("/boot/load", newenv, "Core", tasks)
		if not ok then
			cLinuxPrintError("Core", err)
		end
		print("loading alive")
		print(tostring(#tasks.list))
		sleep(2)
		local ok, err = thread.new("/vit/alive", newenv, "Alive", tasks, tasks)
		if not ok then
			cLinuxPrintError("Alive", err)
		end
		print("loading rednet")
		print(tostring(#tasks.list))
		sleep(2)
		local ok, err = thread.new(lib.rednet.run, newenv, "RedNet", tasks)
		if not ok then
			cLinuxPrintError("RedNet", err)
		end
		print('Loaded Threads')
		print(tostring(#tasks.list))
		sleep(2)


		local running = true
		while running do
			local ok = thread.resumeAll(tasks, evt)
			evt = {os.pullEventRaw()}
			if ok == false then
				running = false
			end
		end
		print(err)
		sleep(2)
	--end
	print("Looks like /vit/alive failed..")
	sleep(1)
	-- NOTE: /boot/load is now in charge of all files to run. If that you know when is
	-- that branch going to die, please do _flag('STATUS_DEAD') to force a restart.
end
os.queueEvent("modem_message", 0)
