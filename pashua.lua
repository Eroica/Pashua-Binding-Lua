--[[ pashua.lua -- Lua bindings for Pashua

Copyright (c) 2018 Eroica

This software is provided 'as-is', without any express or implied warranty. In
no event will the authors be held liable for any damages arising from the use of
this software.

Permission is granted to anyone to use this software for any purpose, including
commercial applications, and to alter it and redistribute it freely, subject to
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim
   that you wrote the original software. If you use this software in a product,
   an acknowledgment in the product documentation would be appreciated but is
   not required.
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

local function run (config, pashua_path)
	if config == nil then error("Mising parameter `config'") end
	if pashua_path then PASHUA_PLACES[#PASHUA_PLACES + 1] = pashua_path end

	local tmp_name = os.tmpname()
	local tmp_file = assert(io.open(tmp_name, "w"))
	tmp_file:write(config)
	tmp_file:close()

	local tmp_readname = os.tmpname()
	local success
	repeat
		if #PASHUA_PLACES > 0 then
			success = os.execute(table.remove(PASHUA_PLACES) .. " " .. tmp_name .. " > " .. tmp_readname .. " 2> /dev/null")
		else
			error("Pashua could not be found!")
		end
	until success

	local t = {}
	local tmp_read = assert(io.open(tmp_readname))
	for line in tmp_read:lines() do
		local key, value = line:match("(%w+)=(.*)")
		t[key] = value
	end

	tmp_read:close()
	os.remove(tmp_name)
	os.remove(tmp_readname)

	return t
end

return {
	run = run
}