local module = {}
module.__index = module

function module.new(code)
	local cpuClass = setmetatable({}, module)

	cpuClass.flags = {
		is_halted = false,
		jump_executed = false,
	}
	cpuClass.registers = {
		x1 = { nil, 0 },
		x2 = { nil, 0 },
		input = { nil, 0 },
		output = { nil, 0 },
	}
	cpuClass.memory = code or { "HLT" }
	cpuClass.instruction_pointer = 1
	cpuClass.error = nil

	return cpuClass
end

function module:update_code(code)
	self.memory = code or { "HLT" }
	self.instruction_pointer = 1
	self.registers = {
		x1 = { nil, 0 },
		x2 = { nil, 0 },
		input = { nil, 0 },
		output = { nil, 0 },
	}
	self.flags = {
		is_halted = false,
		jump_executed = false,
	}
end

function module:get_code()
	return self.memory
end

function module:step()
	if self.flags.is_halted then
		return
	end

	local fetch = self.memory[self.instruction_pointer]
	local args = {}
	for arg in string.gmatch(fetch, "[^%s,]+") do
		table.insert(args, arg)
	end
	local instruction = table.remove(args, 1)

	if instruction == "HLT" then
		self.flags.is_halted = true
		return
	elseif instruction == "ADD" then
		if #args == 2 then
			local result = self.registers[args[1]][2] + tonumber(args[2])
			self.registers[args[1]][2] = result
		end
	elseif instruction == "MOV" then
		self.registers[args[1]] = { "copper-plate", tonumber(args[2]) }
	end

	self:advance_ip()
end

function module:advance_ip()
	if self.flags.jump_executed or self.flags.is_halted then
		return
	end
	self.instruction_pointer = (self.instruction_pointer % #self.memory) + 1
end

function module:is_halted()
	return self.flags.is_halted
end

function module:get_register(register_name)
	return self.registers[register_name]
end

function module.parse_item(str)
	local item, count = str:match("%[item=([^%]]+)%]%s*(%d+)")
	if item and count then
		return { item = item, count = tonumber(count) }
	end

	count, item = str:match("(%d+)%s*%[item=([^%]]+)%]")
	if item and count then
		return { item = item, count = tonumber(count) }
	end

	count = str:match("^%d+$")
	return { item = "ac-generic-1", count = tonumber(count) }
end

return module
