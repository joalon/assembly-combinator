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

    cpuClass.status = {
        is_halted = false,
        jump_executed = false,
        error = false,
    }
    cpuClass.registers = {}
    for i = 0, 31 do
        cpuClass.registers["x" .. i] = 0
    end
    for i = 0, 3 do
        cpuClass.registers["o" .. i] = { name = nil, count = 0 }
    end

    local memory = code or { "HLT" }
    cpuClass.memory = memory
    cpuClass.instruction_pointer = 1

    cpuClass.labels = module.parse_labels(memory)

    cpuClass.errors = {}

    return cpuClass
end

function module:get_errors()
    return self.errors
end

function module:update_code(code)
    local memory = code or { "HLT" }
    self.memory = memory
    self.labels = module.parse_labels(memory)
    self.instruction_pointer = 1
    for i = 0, 31 do
        self.registers["x" .. i] = 0
    end
    for i = 0, 3 do
        self.registers["o" .. i] = { name = nil, count = 0 }
    end
    self.status = {
        is_halted = false,
        jump_executed = false,
        error = false,
    }
    self.errors = {}
end

function module:get_code()
    return self.memory
end

function module:step()
    if self.status.is_halted or self.status.error then
        return
    end

    local fetch = self.memory[self.instruction_pointer]
    fetch = fetch:gsub("^[^:]*:%s*", "")           -- Remove label on current instruction
    fetch = fetch:gsub("#.*", ""):gsub("%s+$", "") -- Remove comments "#" and trailing whitespace

    local args = {}
    for arg in string.gmatch(fetch, "[^%s,]+") do
        table.insert(args, arg)
    end
    local instruction = table.remove(args, 1)

    if instruction == "HLT" then
        self.status.is_halted = true
        return
    elseif instruction == "NOP" then
        -- nop
    elseif instruction == "ADDI" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[ADDI:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments. ADDI expects 3, received " .. #args)
            return
        end
        if args[1] ~= "x0" then
            self.registers[args[1]] = self.registers[args[2]] + tonumber(args[3])
        end
    elseif instruction == "SUB" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[SUB:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments. Expected 3, got " .. #args)
            return
        end
        if args[1] ~= "x0" then
            self.registers[args[1]] = self.registers[args[2]] - self.registers[args[3]]
        end
    elseif instruction == "SLT" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[SLT:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments. Expected 3, got " .. #args)
            return
        end
        if self.registers[args[2]] < self.registers[args[3]] then
            self.registers[args[1]] = 1
        else
            self.registers[args[1]] = 0
        end
    elseif instruction == "SLTI" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[SLTI:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments. Expected 3, got " .. #args)
            return
        end
        if self.registers[args[2]] < tonumber(args[3]) then
            self.registers[args[1]] = 1
        else
            self.registers[args[1]] = 0
        end
    elseif instruction == "WAIT" then
        if #args > 0 then
            if self.status["wait_cycles"] == nil then
                local register_pattern = "^x"
                if args[1]:find(register_pattern) ~= nil then
                    self.status["wait_cycles"] = self.registers[args[1]] - 1
                else
                    self.status["wait_cycles"] = tonumber(args[1]) - 1
                end
                return
            elseif self.status.wait_cycles > 1 then
                self.status.wait_cycles = self.status.wait_cycles - 1
                return
            else
                self.status.wait_cycles = nil
            end
        end
    elseif instruction == "WSIG" then
        local output_register_pattern = "^o"
        if args[1]:find(output_register_pattern) ~= nil then
            self.registers[args[1]] = { name = args[2], count = self.registers[args[3]] }
        else
            self.status.error = true
            table.insert(self.errors,
                "[WSIG:" ..
                self.instruction_pointer .. "] " .. "Unexpected output register name. Expected o0-o3, got " .. args[1])
            return
        end
    elseif instruction == "JAL" then
        if #args ~= 2 then
            self.status.error = true
            table.insert(self.errors,
                "[JAL:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments, expected 2, got " .. #args)
            return
        end
        if args[1] ~= "x0" then
            self.registers[args[1]] = self.instruction_pointer
        end
        self.instruction_pointer = self.labels[args[2]]
        self.status.jump_executed = true
    elseif instruction == "BEQ" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[BEQ:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments, expected 3, got " .. #args)
            return
        end
        if self.registers[args[1]] == self.registers[args[2]] then
            self.instruction_pointer = self.labels[args[3]]
            self.status.jump_executed = true
        end
    elseif instruction == "BNE" then
        if #args ~= 3 then
            self.status.error = true
            table.insert(self.errors,
                "[BNE:" ..
                self.instruction_pointer .. "] " .. "Unexpected number of arguments, expected 3, got " .. #args)
            return
        end
        if self.registers[args[1]] ~= self.registers[args[2]] then
            self.instruction_pointer = self.labels[args[3]]
            self.status.jump_executed = true
        end
    else
        if instruction ~= nil then
            table.insert(self.errors, "Unexpected instruction on line " .. self.instruction_pointer .. ": " ..
                instruction)
            self.status.error = true
            return
        end
    end

    self:advance_ip()
end

function module:advance_ip()
    if self.status.is_halted or self.status.error then
        return
    end
    if self.status.jump_executed then
        self.status.jump_executed = false
        return
    end
    self.instruction_pointer = (self.instruction_pointer % #self.memory) + 1
end

function module:is_halted()
    return self.status.is_halted
end

function module:get_register(register_name)
    return self.registers[register_name]
end

return module
