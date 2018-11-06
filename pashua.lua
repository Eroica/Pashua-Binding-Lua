--[[ pashua.lua -- Lua bindings for Pashua

Copyright (C) 2018 Eroica

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]]

local BUNDLE_PATH = "Pashua.app/Contents/MacOS/Pashua"
local PASHUA_PLACES = {
	"/Applications/" .. BUNDLE_PATH,
	"~/Applications/" .. BUNDLE_PATH,
	"./" .. BUNDLE_PATH,
}

--- Opens file, runs function and closes/removes file. Poor man’s RAII.
-- @tparam string filename
-- @tparam string mode File mode
-- @tparam function lambda Function to run with file
local function with_file (filename, mode, lambda)
	local file = assert(io.open(filename, mode))
	local _, message = pcall(lambda, file)
	if file then
		file:close()
		os.remove(filename)
	end
	if message then error(message) end
end


--- Runs Pashua.app with specified configuration
-- @tparam string config
-- @tparam string pashua_path Path to Pashua binary (optional)
-- @treturn {string,...} Return values from Pashua.app
local function run (config, pashua_path)
	if config == nil then error("Mising parameter `config'", 2) end
	if pashua_path then PASHUA_PLACES[#PASHUA_PLACES + 1] = pashua_path end

	local t, tmp_confname, tmp_resultname = {}, os.tmpname(), os.tmpname()
	with_file(tmp_confname, "w", function (config_file)
		config_file:write(config)
		config_file:flush()

		with_file(tmp_resultname, "r", function (result_file)
			-- Try to run Pashua.app from the last element in PASHUA_PLACES.
			-- This will remove this element from PASHUA_PLACES after each
			-- call UNTIL `os.execute' returns true.
			repeat
				if #PASHUA_PLACES == 0 then
					error("Pashua could not be found!")
				end
				local pashua_call = string.format("%s %s > %s 2> /dev/null",
				                                  table.remove(PASHUA_PLACES),
				                                  tmp_confname, tmp_resultname)
			until os.execute(pashua_call)

			for line in result_file:lines() do
				local key, value = line:match("(%w+)=(.*)")
				t[key] = value
			end
		end)
	end)

	return t
end


return {
	run = run
}
