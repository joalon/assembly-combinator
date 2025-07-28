local module = {}
module.__index = module

function module.parse_labels(code)
	local label_pattern = "^%s*([%w_][%w_]*):.*$"
	local labels = {}
	for i, line in ipairs(code) do
		if line:match(label_pattern) then
			local label_name = module.extract_label_name(line)
			labels[label_name] = i
		end
	end
	return labels
end

function module.extract_label_name(line)
	local label_name_pattern = "^%s*([%w_][%w_]*):.*$"
	return line:match(label_name_pattern)
end

function module.new(code)
	local cpuClass = setmetatable({}, module)

	cpuClass.flags = {
		is_halted = false,
		jump_executed = false,
	}
	cpuClass.registers = {}
	for i = 0, 31 do
		cpuClass.registers["x" .. i] = 0
	end

	local memory = code or { "HLT" }
	cpuClass.memory = memory
	cpuClass.instruction_pointer = 1

	cpuClass.labels = module.parse_labels(memory)

	return cpuClass
end

function module:update_code(code)
	local memory = code or { "HLT" }
	self.memory = memory
	self.labels = module.parse_labels(memory)
	self.instruction_pointer = 1
	for i = 0, 31 do
		self.registers["x" .. i] = 0
	end
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
	fetch = fetch:gsub("^[^:]*:%s*", "") -- Remove label

	local args = {}
	for arg in string.gmatch(fetch, "[^%s,]+") do
		table.insert(args, arg)
	end
	local instruction = table.remove(args, 1)

	if instruction == "HLT" then
		self.flags.is_halted = true
		return
	elseif instruction == "NOP" then
	-- nop
	elseif instruction == "ADDI" then
		self.registers[args[1]] = self.registers[args[2]] + tonumber(args[3])
	elseif instruction == "SUB" then
		self.registers[args[1]] = self.registers[args[2]] - self.registers[args[3]]
	elseif instruction == "WAIT" then
		if self.flags["wait_cycles"] == nil then
			self.flags["wait_cycles"] = tonumber(args[1]) - 1
			return
		elseif self.flags.wait_cycles > 1 then
			self.flags.wait_cycles = self.flags.wait_cycles - 1
			return
		else
			self.flags.wait_cycles = nil
		end
	elseif instruction == "JAL" then
		if args[1] ~= "x0" then
			self.registers[args[1]] = self.instruction_pointer
		end
		self.instruction_pointer = self.labels[args[2]]
		self.flags.jump_executed = true
	elseif instruction == "BEQ" then
		if self.registers[args[1]] == self.registers[args[2]] then
			self.instruction_pointer = self.labels[args[3]]
			self.flags.jump_executed = true
		end
	elseif instruction == "BNQ" then
		if self.registers[args[1]] ~= self.registers[args[2]] then
			self.instruction_pointer = self.labels[args[3]]
			self.flags.jump_executed = true
		end
	end

	if not self.flags.jump_executed then
		self:advance_ip()
	else
		self.flags.jump_executed = false
	end
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

return module
