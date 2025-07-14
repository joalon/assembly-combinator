-- TODO: Remove on_init for release
script.on_init(function()
	local freeplay = remote.interfaces["freeplay"]
	if freeplay then -- Disable freeplay popup-message
		if freeplay["set_skip_intro"] then
			remote.call("freeplay", "set_skip_intro", true)
		end
		if freeplay["set_disable_crashsite"] then
			remote.call("freeplay", "set_disable_crashsite", true)
		end
	end
	remote.call(
		"freeplay",
		"set_created_items",
		{ ["assembly-combinator"] = 5, ["constant-combinator"] = 5, ["selector-combinator"] = 5 }
	)

	storage.players = {}
end)

require("script.asm")
