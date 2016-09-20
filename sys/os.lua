
local tTables = {}
local tReadOnly = {}
local native_rawset = rawset
local mt = {
                __metatable = 'Attempt to get protected metatable',
                __newindex = function(self, key, value)
                        if not tTables[self][key] then
                                native_rawset(self, key, value)
                                return
                        end
                        error('Try to write to read only table', 2)
                end
}
mt.__index = function (self, key)
                local var = tTables[self][key]
                if type(var) == 'table' then
                                setmetatable({}, mt)
                end
                return var
end

_G.rawset = function (tab, key, value)
                if tReadOnly[tab] then error('Try to write to read only table', 2) end
                return native_rawset(tab, key, value)
end

local function createReadOnly (tab)
                if type(tab) ~= 'table' then
                                error('table expected, got ' .. type(tab), 2)
                end
                local self = setmetatable({}, mt)
                tTables[self] = tab
                tReadOnly[self] = true
                return self
end

local oldOpen = fs.open
local oldmkdir = fs.makeDir
local oldMove = fs.move            ------- This should run outside of init(), to prevent programs having access to it
local oldCopy = fs.copy
local oldDelete = fs.delete




local function init()
--[[
	CLinux
	A Linux-tryhard OS
	
	You will probably like the original more.
	
	This OS will defenitely not be as polished, 
	as DoorOS. Thats why I recommend DoorOS more than that.
	
	This OS will stay in "Command-Line"-mode, that means
	you guys can make your own, installable Desktop-Enviroment!
	
	(Yes I will probably consider adding my DoorOS-Desktop, when the command-line
	is polished enough...)
]]
--APIs (WILL PROBABLY BE IMPORTANT FOR DESKTOP ENVIROMENTS TOO)
os.loadAPI("/sys/API/sha")
X = nil --ENTER THE PATH TO YOUR DESKTOP ENVIROMENT, IF IT'S NOT NIL IT WILL TRY TO LOAD IT

--Variablen
_ver = 0.1
os.version = function()
	return "CLinux Version "..tostring(_ver)
end

_verstr = os.version()
local usrData = {
	usrName = {},
	password = {},
}
local tmpUsr = ""
local tmpPw = ""
local cUsrNmbr = 1
local oldCUsr = ""
local oldCPw = ""
local oldCDir = ""
currentUsr = ""
currentPw = ""
currentDir = ""

currentDir = "/usr/"

local function changeDir(dest)
	local goback = false
		--local a, b = string.find(dest, "[..]")
		if dest == ".." then
			goback = true
		else
			goback = false
		end
	if dest == "~" then
		dest = "/usr/"..currentUsr.."/home/"
	end
	local a, b = string.find(dest, "//")
	local falseDir = false
	if a ~= nil and a >= 1 and b > 1 and goback == false then
		falseDir = true
	end
	local a, b = string.find(dest, "/", 1)
	if a == 1 and goback == false and falseDir == false then
		--inthis = false
	elseif falseDir == false then
		--inthis = true
		dest = currentDir..dest
	end
	if fs.isDir(dest) and falseDir == false then
		local found = false
		
		
		
		local a, b = string.find(dest, "/", #dest)
		if a == #dest and goback == false then
			found = true
		end
		if found == false and goback == false then
			currentDir = dest.."/"
		elseif found == true and goback == false then
			currentDir = dest
		elseif goback and currentDir ~= "/" then
			dest = currentDir
			dest = string.reverse(dest)
			local i, j = string.find(dest, "/")
			if i then
				dest = string.sub(dest, j+1, #dest)
				local i, j = string.find(dest, "/")
				dest = string.sub(dest, j+1, #dest)
				dest = string.reverse(dest)
				currentDir = dest.."/"
			else
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print("Error.")
				term.setTextColor(col)
			end
		end
		return true
	else
		local col = term.getTextColor()
		term.setTextColor(colors.red)
		print("No such directory.")
		term.setTextColor(col)
		return false
	end
end
--Backup



--Wichtige tabellen/variablen für den coroutine-manager

local c = {
	c = {},--Here are the saved coroutines in a table, basically I will add the command "ps", to list the processes using the PIDs (basically the keys in every entry, e.g. 1,2,3,4,etc.)
	w = {}, --The individual window of every coroutines, mainly used to prevent redrawing the screen all the time
} 

--Funktionen







--[[
										DUMMYFILES
		Please add your workarounds for called functions here, which are not available
		due to dumping CraftOS

		For example the Shell API
]]






function setShellAPI(p)
	shell = {}
	shell.workPath = p
	aliases = {} -- NOTE: THESE ARE NOT USED, THEY ARE ONLY USED TO PREVENT CRASHING THE PROGRAM
	function shell.path()
		return ".:/sys/:/sys/API/:"..shell.workPath
	end
	function shell.dir()
		return shell.workPath
	end
	function shell.run(path, ...)
		local x, y = string.find(path, "/rom/programs/")
		if x ~= 1 then
			local t = {...}
			local file, err = oldOpen(path, "r")
			local inhalt = file.readAll()
			file.close()
			local prog = loadstring(inhalt)
			local oldWPath = shell.workPath
			local p = string.reverse(path)
			local x, y = string.find(p, "/")
			local p = string.sub(p, x+1, #p)
			if p == nil or p == "" or p == " " then
				p = "/"
			else
				p = string.reverse(p)
			end
			shell.workPath = p
			local env = getfenv(shell.run)
			setfenv(prog, env)
			local ok, err, b = pcall(prog, unpack(t))
			shell.workPath = oldWPath
			return ok, err, b
		else
			return false, "Cannot access rom"
		end
	end
	function shell.exit()
		return
	end
	function shell.setPath(path)
		shell.workPath = path
		return
	end
	function shell.resolve(a)
		if fs.exists(shell.workPath..a) then
			return shell.workPath..a
		else
			return
		end
	end
	function shell.resolveProgram(prog)
		if fs.exists("/usr/bin/"..prog) then
			return "/usr/bin/"..prog
		elseif fs.exists("/rom/programs/"..prog) then
			return "/rom/programs/"..prog
		elseif fs.exists("/rom/programs/turtle/"..prog) then
			return "/rom/programs/turtle/"..prog
		elseif fs.exists("/rom/programs/rednet/"..prog) then
			return "/rom/programs/rednet/"..prog
		elseif fs.exists("/rom/programs/pocket/"..prog) then
			return "/rom/programs/pocket/"..prog
		elseif fs.exists("/rom/programs/http/"..prog) then
			return "/rom/programs/http/"..prog
		elseif fs.exists("/rom/programs/fun/"..prog) then
			return "/rom/programs/fun/"..prog
		elseif fs.exists("/rom/programs/command/"..prog) then
			return "/rom/programs/command/"..prog
		elseif fs.exists("/rom/programs/advanced/"..prog) then
			return "/rom/programs/advanced/"..prog
		else
			return
		end
	end
	function shell.aliases()
		return aliases
	end
	function shell.setAlias(a, b)
		aliases[a] = b
	end
	function shell.clearAlias(a)
		aliases[a] = nil
	end
	function shell.programs(hidden)
		if hidden == nil then hidden = false end
		local total = {}
		local romprogs = fs.list("/rom/programs/")
		local localprog = fs.list(shell.workPath)
		for _, a in ipairs(romprogs) do
			if hidden == false then
				local x, y = string.find(a, "[.]")

				if x == 1 and y == 1 then
				else
					if fs.isDir("/rom/programs/"..a) == false then
						table.insert(total, a)
					end
				end
			else
				if fs.isDir("/rom/programs/"..a) == false then
					table.insert(total, a)
				end
			end
		end
		for _, a in ipairs(localprog) do
			if hidden == false then
				local x, y = string.find(a, "[.]")

				if x == 1 and y == 1 then
				else
					if fs.isDir("/usr/bin/"..a) == false then
						table.insert(total, a)
					end
				end
			else
				if fs.isDir("/usr/bin/"..a) == false then
					table.insert(total, a)
				end
			end
		end
		return total
	end
	function shell.getRunningProgram()
		return shell.workPath
	end
	function shell.openTab()
		return
	end								--THESE WILL NOT BE SUPPORTED, UNFORTUNATELY
	function shell.switchTab()
		return
	end
	function shell.complete()
		local t = {}
		return t
	end
	function shell.completeProgram(prefix)
		local pList = fs.list("/usr/bin/")
		local total = {}

		for _, a in ipairs(pList) do
			local x, y = string.find(a, prefix)
			if x == 1 then
				local b = string.sub(a, y+1, #a)
				table.insert(total, b)
			end
		end
		return total
	end
	function shell.setCompletionFunction()
		return false
	end
	function shell.getCompletionInfo()
		return
	end
end









function clear(bg, fg) --did you know that you can see this function in any of my codes? xD
	term.setCursorPos(1,1)
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
	term.clear()
end

function limitRead(nmbr, a)
	term.setCursorBlink(true)
	str = ""
	local reading = true
	while reading do
		local _, key = os.pullEventRaw()
		if _ == "char" then
			if #str < nmbr and a == nil then
				term.write(key)
				str = str..key
			else
				term.write(a)
				str = str..key
			end
		elseif _ == "key" and key == keys.backspace then
			if #str > 0 then
				str = string.reverse(str)
				str = string.sub(str, 2)
				str = string.reverse(str)
				local x, y = term.getCursorPos()
				term.setCursorPos(x-1, y)
				term.write(" ")
				term.setCursorPos(x-1, y)
			end
		elseif _ == "key" and key == keys.enter then
			term.setCursorBlink(false)
			return str
			
				
		end
	end
end


function limitReadPw(nmbr)
	term.setCursorBlink(true)
	str = ""
	local reading = true
	while reading do
		local _, key = os.pullEventRaw()
		if _ == "char" then
			if #str < nmbr then
				str = str..key
			end
		elseif _ == "key" and key == keys.backspace then
			if #str > 0 then
				str = string.reverse(str)
				str = string.sub(str, 2)
				str = string.reverse(str)
			end
		elseif _ == "key" and key == keys.enter then
			term.setCursorBlink(false)
			return str
			
				
		end
	end
end


local function register(step)
	clear(colors.black, colors.white)
	if step == 1 then
		term.write("Username: ")
		tmpUsr = limitRead(16)
		print("")
		if #tmpUsr < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter an username.")
			term.setTextColor(col)
			register(1)
		elseif tmpUsr == "root" then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please use another name.")
			term.setTextColor(col)
			register(1)
		else
			register(2)
		end
		
	elseif step == 2 then
		term.write("Password: ")
		tmpPw = limitReadPw(99)
		if #tmpPw < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter a password.")
			term.setTextColor(col)
			register(2)
		else
			register(3)
		end
		
	elseif step == 3 then
		term.write("Repeat Password: ")
		local pw = limitReadPw(99)
		print("")
		if #pw < 1 or pw ~= tmpPw then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Passwords do not match.")
			term.setTextColor(col)
			register(2)
		else
			register(4)
		end
		
		
	elseif step == 4 then
		print("Account "..tmpUsr.." successfully created.")
		table.insert(usrData.usrName, tmpUsr)
		tmpPw = sha.pbkdf2(tmpPw, tmpUsr, 10):toHex()
		table.insert(usrData.password, tostring(tmpPw))
		local file = fs.open("/sys/usrData","w")
		local a = textutils.serialize(usrData)
		file.write(a)
		file.close()
		fs.makeDir("/usr/"..tmpUsr.."/home/")
		fs.makeDir("/usr/root/home/")
		print("Done.")
	end
end

local function login(step)
	if step == 1 then
		
		nTerm = term.native()
		term.write("Username: ")
		local e = limitRead(16)
		print("")
		if #e < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter an username.")
			term.setTextColor(col)
			login(1)
		else
			for _, name in ipairs(usrData.usrName) do
				if name == e then
					currentUsr = e
					cUsrNmbr = _
					login(2)
				elseif e == "root" then
					currentUsr = e
					cUsrNmbr = 0
					login(2)
				elseif _ == #usrData.usrName then
					local col = term.getTextColor()
					term.setTextColor(colors.red)
					print("User not found.")
					term.setTextColor(col)
					login(1)
				end
			end
		end
	elseif step == 2 then
		term.write("Password: ")
		local p = limitReadPw(99)
		print("")
		if #p < 1 then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Please enter a password.")
			term.setTextColor(col)
			login(2)
		else
			p = sha.pbkdf2(p, currentUsr, 10):toHex()
			p = tostring(p)
			local file = fs.open("/sys/.rootpw","r")
			local rpw = file.readLine()
			file.close()
			if currentUsr ~= "root" and p ~= usrData.password[cUsrNmbr] then
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print("Oops, that didn't work! Let's try it again.")
				term.setTextColor(col)
				login(1)
			elseif currentUsr == "root" and p ~= rpw then
				local col = term.getTextColor()
				term.setTextColor(colors.red)
				print("Oops, that didn't work! Let's try it again.")
				term.setTextColor(col)
				login(1)
			else
				--stuff
				currentDir = "/usr/"..currentUsr.."/home/"
				--vDir = "/usr/"..currentUsr.."/home/"
				currentUsr = currentUsr
				currentDir = currentDir
				currentPw = p
				--_G.currentPw = p
				print("Success.")
				--limitFunctions()
				userHomeDir = "/usr/"..currentUsr.."/home/"
				linuxShell()
			end
		end
	end
end



function limitFunctions()
	fs.open = function(path, mode)
		if mode ~= "a" or mode ~= "w" or mode ~= "r" or mode ~= "br" or mode ~= "bw" then
			return nil
		end
		local a, b = string.find(path, userHomeDir)
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if mode == "a" and inhome == false or mode == "w" and inhome == false or mode == "bw" and inhome == false then
			return fs.open(userHomeDir..path, mode)
		elseif mode == "a" and inhome or mode == "w" and inhome or mode == "bw" and inhome then
			return fs.open(path, mode)
		elseif mode == "r" or mode == "br" then
			return fs.open(path, mode)
		end
	end
	fs.makeDir = function(path)
		local a, b = string.find(path, userHomeDir)
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if inhome == false then
			return fs.makeDir(userHomeDir..path, mode)
		elseif inhome then
			if fs.exists(path) == false then
				return fs.makeDir(path)
			else
				return "Folder/File already exists."
			end
		end
	end
	fs.move = function(oldPath, newPath)
		local a, b = string.find(oldPath, userHomeDir)
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		local a, b = string.find(newPath, userHomeDir)
		local tohome = false
		if a == nil then
			tohome = false
		else
			tohome = true
		end
		if inhome == false or tohome == false then
			if inhome == false and tohome then
				return fs.move(userHomeDir..oldPath, newPath)
			elseif tohome == false and inhome then
				return fs.move(oldPath, userHomeDir..newPath)
			else
				return false
			end
		elseif inhome and tohome then
			if fs.exists(oldPath) and fs.exists(newPath) == false then
				return fs.move(oldPath, newPath)
			elseif fs.exists(oldPath) == false then
				return "Folder/File does not exist."
			elseif fs.exists(newPath) then
				return "Folder/File already exists."
			end
		end
	end
	fs.copy = function(oldPath, newPath)
		local a, b = string.find(newPath, userHomeDir)
		local tohome = false
		if a == nil then
			tohome = false
		else
			tohome = true
		end
		if tohome == false then
			return fs.copy(oldPath, userHomeDir..newPath)
		elseif tohome then
			if fs.exists(oldPath) and fs.exists(newPath) == false then
				return fs.copy(oldPath, newPath)
			elseif fs.exists(oldPath) == false then
				return "Folder/File does not exist."
			elseif fs.exists(newPath) then
				return "Folder/File already exists."
			end
		end
	end
	fs.delete = function(path)
		local a, b = string.find(path, userHomeDir)
		local inhome = false
		if a == nil then
			inhome = false
		else
			inhome = true
		end
		if inhome == false then
			return fs.delete(userHomeDir..path)
		elseif inhome then
			if fs.exists(path) then
				return fs.delete(path)
			elseif fs.exists(path) == false then
				return "Folder/File does not exist."
			end
		end
	end
	oldCUsr = currentUsr
	oldCPw = currentPw
	oldCDir = currentDir
	--[[local sandBox = setmetatable({}, {
		__index = _G
	})]]



	--restoreFunctions()
	--return sandBox
end

local function restoreFunctions()
	fs.open = oldOpen
	fs.makeDir = oldmkdir
	fs.delete = oldDelete
	fs.move = oldMove
	fs.copy = oldCopy
	currentUsr = oldCUsr
	currentPw = oldCPw
	currentDir = oldCDir
end

function linuxShell()
	clear(colors.black, colors.white)
	local loop = true
	local d = "/"

	while loop do
		currentDir = currentDir
		local x, y = term.getCursorPos()
		term.setCursorPos(1,y)
		term.setTextColor(colors.yellow)
		local a, b = string.find(currentDir, "/usr/"..currentUsr.."/home/")
		if a then
			d = string.gsub(currentDir, "/usr/"..currentUsr.."/home/", "~/", 1)
		else
			d = currentDir
		end
		
		term.write(currentUsr.."@ ")
		term.setTextColor(colors.blue)
		term.write(d.."> ")
		term.setTextColor(colors.white)
		term.setCursorBlink(true)
		local command = read()
		local args = {}
		local arg = ""
		local i, j = string.find(command, " ")
		if i == nil then
			command = command
		else
			arg = string.sub(command, j+1, #command)
			command = string.sub(command, 1, i-1)
			
		end
		
		if arg == nil or arg == "" then
			arg = ""
		else
			repeat
				local i, j = string.find(arg, " ")
				if i ~= nil then
					local a = string.sub(arg, 1, i-1)
					local x, y = string.find(a, "~/")
					if x == 1 and y == 2 then
						local c = string.sub(a, 3, #a)
						a = "/usr/"..currentUsr.."/home/"..c
					end
					table.insert(args, a)
					arg = string.sub(arg, j+1, #arg)
				else
					local i, j = string.find(arg, "~/")
					if i == 1 and j == 2 then
						local c = string.sub(arg, 3, #arg)
						arg = "/usr/"..currentUsr.."/home/"..c
					end
					table.insert(args, arg)
				end
			until i == nil
		end
		sudo = false
		if command == "sudo" then
			if #args > 0 then
				sudo = true
				command = args[1]
				table.remove(args, 1)
			else
				sudo = false
				command = " "
			end
		end
		if currentUsr == "root" then
			sudo = true
		end

		if fs.exists("/usr/bin/"..command) and fs.exists(currentDir..command) == false then
			if sudo == false then
				local a = loadfile("/usr/bin/"..command)
				setShellAPI("/usr/bin/")
				limitFunctions()
				local e = getfenv(init)
				local sandBox = createReadOnly(e)
				setfenv(a, sandBox)
				local ok, err = pcall(a, unpack(args))
				restoreFunctions()
				if ok == false or ok == nil then
					local col = term.getTextColor()
					term.setTextColor(colors.red)
					print(err)
					term.setTextColor(col)
				end
			elseif sudo == true then
				if currentUsr ~= "root" then
					sudo = false
					term.write("Please enter root password: ")
					local p = limitReadPw(99)
					print("")
					local file = fs.open("/sys/.rootpw", "r")
					local rpw = file.readLine()
					file.close()
					p = sha.pbkdf2(p, "root", 10):toHex()
					p = tostring(p)
					if #p < 1 or p ~= rpw then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Wrong password.")
						term.setTextColor(c)
					elseif p == rpw then
						local a = loadfile("/usr/bin/"..command)
						setShellAPI("/usr/bin/")
						local oldCUsr = currentUsr
						local oldCPw = currentPw
						currentUsr = "root"
						currentPw = rpw
						local e = getfenv(init)
						local sandBox = createReadOnly(e)
						setfenv(a, sandBox)
						local ok, err = pcall(a, unpack(args))
						if ok == false or ok == nil then
							local col = term.getTextColor()
							term.setTextColor(colors.red)
							print(err)
							print("Have you tried 'sudo'?")
							term.setTextColor(col)
						end
						currentUsr = oldCUsr
						currentPw = oldCPw
					end
				elseif currentUsr == "root" then
					sudo = false
					local file = fs.open("/sys/.rootpw", "r")
					if file == nil then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Error: .rootpw not found.")
					end
					local rpw = file.readLine()
					file.close()
					if p ~= rpw then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Wrong password.")
					else
						local a = loadfile("/usr/bin/"..command)
						setShellAPI("/usr/bin/")
						local oldCUsr = currentUsr
						local oldCPw = currentPw
						local e = getfenv(init)
						local sandBox = createReadOnly(e)
						setfenv(a, sandBox)
						local ok, err = pcall(a, unpack(args))
						if ok == false or ok == nil then
							local col = term.getTextColor()
							term.setTextColor(colors.red)
							print(err)
							print("Have you tried 'sudo'?")
							term.setTextColor(col)
						end
						currentUsr = oldCUsr
						currentPw = oldCPw
					end
				else
					local c = term.getTextColor()
					term.setTextColor(colors.red)
					print("Error: User not found. ("..currentUsr..")")
				end
			end
--[[							NOT YET IMPLEMENTED:




		elseif fs.exists("/usr/bin/"..command) and command ~= "cd" then
			if sudo == false then
				local nProc = #c.c+1
				fs.copy("/usr/bin/"..command, "/tmp/"..tostring(nProc))
				local file = fs.open("/tmp/"..tostring(nProc), "r")
				local inhalt = file.readAll()
				file.close()
				local file = fs.open("/tmp/"..tostring(nProc), "w")
				file.write("local function init()\n")
				file.write(inhalt.."\n")
				file.write("end\n")
				file.write("init()")
				file.close()



				local a = loadfile("/usr/bin/"..command)

				limitFunctions()
				local e = getfenv(init)
				local sandBox = createReadOnly(e)
				setfenv(a, sandBox)
				--a, unpack(args)
				c.c[nProc] = coroutine.create(pcall)
				c.w[nProc] = window.create(oldTerm, 1, 1, 51, 19)
				term.redirect(c.w[nProc])
				clear(colors.black, colors.white)
				inProgram = nProc
				restoreFunctions()
			elseif sudo == true then
				sudo = false
				term.write("Please enter root password: ")
				local p = limitReadPw(99)
				local file = fs.open("/sys/.rootpw", "r")
				local rpw = file.readLine()
				file.close()
				p = sha.pbkdf2(p, "root", 10):toHex()
				p = tostring(p)
				if #p < 1 or p ~= rpw then
					local c = term.getTextColor()
					term.setTextColor(colors.red)
					print("Wrong password.")
					term.setTextColor(c)
				elseif p == rpw then
					local nProc = #c.c+1
					local a = loadfile("/usr/bin/"..command)
					limitFunctions()
					local oldCUsr = _G.currentUsr
					local oldCPw = _G.currentPw
					_G.currentUsr = "root"
					_G.currentPw = rpw
					local e = getfenv(init)
					local sandBox = createReadOnly(e)
					setfenv(a, sandBox)
					c.c[nProc] = coroutine.create(pcall)
					c.w[nProc] = window.create(oldTerm, 1, 1, 51, 19)
					term.redirect(c.w[nProc])
					clear(colors.black, colors.white)
					inProgram = nProc
					restoreFunctions()
				end
			end
]]






		elseif command == "cd" and command ~= nil or command ~= "" and command == "cd" then
			
			if #args < 1 or #args > 1 then
				print("Usage:")
				print("		cd <path>")
			else
				changeDir(args[1])
			end
		elseif fs.exists(currentDir..command) then
			if sudo == false then
				local a = loadfile(currentDir..command)
				setShellAPI(currentDir)
				limitFunctions()
				local e = getfenv(init)
				local sandBox = createReadOnly(e)
				setfenv(a, sandBox)
				local ok, err = pcall(a, unpack(args))
				restoreFunctions()
				if ok == false or ok == nil then
					local col = term.getTextColor()
					term.setTextColor(colors.red)
					print(err)
					term.setTextColor(col)
				end
			elseif sudo == true then
				if currentUsr ~= "root" then
					sudo = false
					term.write("Please enter root password: ")
					local p = limitReadPw(99)
					print("")
					local file = fs.open("/sys/.rootpw", "r")
					local rpw = file.readLine()
					file.close()
					p = sha.pbkdf2(p, "root", 10):toHex()
					p = tostring(p)
					if #p < 1 or p ~= rpw then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Wrong password.")
						term.setTextColor(c)
					elseif p == rpw then
						local a = loadfile(currentDir..command)
						setShellAPI(currentDir)
						local oldCUsr = currentUsr
						local oldCPw = currentPw
						currentUsr = "root"
						currentPw = rpw
						local e = getfenv(init)
						local sandBox = createReadOnly(e)
						setfenv(a, sandBox)
						local ok, err = pcall(a, unpack(args))
						if ok == false or ok == nil then
							local col = term.getTextColor()
							term.setTextColor(colors.red)
							print(err)
							print("Have you tried 'sudo'?")
							term.setTextColor(col)
						end
						currentUsr = oldCUsr
						currentPw = oldCPw
					end
				elseif currentUsr == "root" then
					sudo = false
					local file = fs.open("/sys/.rootpw", "r")
					if file == nil then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Error: .rootpw not found.")
					end
					local rpw = file.readLine()
					file.close()
					if p ~= rpw then
						local c = term.getTextColor()
						term.setTextColor(colors.red)
						print("Wrong password.")
					else
						local a = loadfile(currentDir..command)
						setShellAPI(currentDir)
						local oldCUsr = currentUsr
						local oldCPw = currentPw
						local e = getfenv(init)
						local sandBox = createReadOnly(e)
						setfenv(a, sandBox)
						local ok, err = pcall(a, unpack(args))
						if ok == false or ok == nil then
							local col = term.getTextColor()
							term.setTextColor(colors.red)
							print(err)
							print("Have you tried 'sudo'?")
							term.setTextColor(col)
						end
						currentUsr = oldCUsr
						currentPw = oldCPw
					end
				else
					local c = term.getTextColor()
					term.setTextColor(colors.red)
					print("Error: User not found. ("..currentUsr..")")
				end
			end
		elseif fs.exists("/usr/bin/"..command) == false and fs.exists(currentDir..command) == false then
			local col = term.getTextColor()
			term.setTextColor(colors.red)
			print("Command not found.")
			term.setTextColor(col)
		elseif command == nil or command == "" then
		end
		
	end
end


local function checkUsr()
	print("Welcome to ".._verstr.."!")
	sleep(1)
	local file = fs.open("/sys/usrData","r")
	usrData = file.readAll()
	usrData = textutils.unserialize(usrData)
	file.close()
	
	if #usrData.usrName < 1 then
		term.setTextColor(colors.red)
		print("No user(s) found.")
		print("Starting registration.")
		term.setTextColor(colors.white)
		sleep(2)
		register(1)
	else
		--[[
		
		EXAMPLE LOGIN SYSTEM:
		
		print(usrData.usrName[1])
		local a = limitReadPw(16)
		a = sha.pbkdf2(a, usrData.usrName[1], 10):toHex()
		a = tostring(a)
		if a == usrData.password[1] then
			print("true")
		else
			print("False")
		end]]
		clear(colors.black, colors.white)
		login(1)
	end
end

--Code

clear(colors.black, colors.white)
fs.delete("/tmp/*")
checkUsr()

end

init()