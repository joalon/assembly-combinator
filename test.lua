require("busted.runner")()

local cpu = require("script.cpu")

describe("CPU tests", function()
	it("can advance the instruction pointer", function()
		local code = {
			"ADDI x10, x0, 1",
			"ADDI x10, x10, 2",
			"ADDI x10, x10, 3",
		}
		local myCpu = cpu.new(code)

		assert.is_true(myCpu.instruction_pointer == 1)
		myCpu:advance_ip()
		myCpu:advance_ip()
		myCpu:advance_ip()
		myCpu:advance_ip()
		assert.is_true(myCpu.instruction_pointer == 2)
		myCpu:advance_ip()
		assert.is_true(myCpu.instruction_pointer == 3)
	end)

	it("can halt", function()
		local myCpu = cpu.new({ "HLT" })
		myCpu:step()
		assert.is_true(myCpu:is_halted())

		myCpu = cpu.new()
		myCpu:step()
		assert.is_true(myCpu:is_halted())
	end)

	it("can wait", function()
		local code = {
			"WAIT 3",
			"ADDI x10, x0, 13",
			"HLT",
		}

		local myCpu = cpu.new(code)

		for _ = 1, 3 do
			myCpu:step()
		end

		local first_result = myCpu:get_register("x10")
		myCpu:step()
		local second_result = myCpu:get_register("x10")
		myCpu:step()

		assert.are.equal(first_result, 0)
		assert.are.equal(second_result, 13)
		assert.is_true(myCpu:is_halted())
	end)

	it("can execute an immediate add and halt", function()
		local myCpu = cpu.new({ "ADDI x10, x0, 2", "HLT" })
		myCpu:step()
		local amount = myCpu:get_register("x10")

		assert.are.equal(amount, 2)
		assert.is_false(myCpu:is_halted())

		myCpu:step()
		assert.is_true(myCpu:is_halted())
	end)

	it("can execute multiple immediate adds and halt", function()
		local code = {
			"ADDI x10, x0, 1",
			"ADDI x10, x10, 2",
			"ADDI x10, x10, 3",
			"HLT",
		}
		local myCpu = cpu.new(code)

		for _ = 1, 4 do
			myCpu:step()
		end

		local result = myCpu:get_register("x10")

		assert.are.equal(6, result)
		assert.is_true(myCpu:is_halted())
	end)

	it("can execute subtracts", function()
		local code = {
			"ADDI x10, x0, 0",
			"ADDI x11, x0, 3",
			"SUB x10, x10, x11",
			"SUB x10, x10, x11",
			"HLT",
		}
		local myCpu = cpu.new(code)

		while not myCpu:is_halted() do
			myCpu:step()
		end

		local result = myCpu:get_register("x10")

		assert.are.equal(-6, result)
		assert.is_true(myCpu:is_halted())
	end)

	it("can get label name from source code line", function()
		local test_lines = {
			{ input = "main:", expected = "main" },
			{ input = "  loop:", expected = "loop" },
			{ input = "    main:", expected = "main" },
			{ input = "start_func:", expected = "start_func" },
			{ input = "  inner_loop: NOP", expected = "inner_loop" },
			{ input = "label1: ADD x1, x2", expected = "label1" },
		}

		for _, test in ipairs(test_lines) do
			assert.are.equal(test.expected, cpu.extract_label_name(test.input))
		end
	end)

	it("can get labels with line number from source code", function()
		local test_code = {
			"main:",
			"    ADDI x1, x0, 10",
			"loop:",
			"    ADDI x1, x1, -1",
			"    BNE x1, x0, loop",
			"    JAL x1, main",
			"    inner: NOP",
		}
		local expected = {
			main = 1,
			loop = 3,
			inner = 7,
		}

		local results = cpu.parse_labels(test_code)
		assert.are.equal(#expected, #results)
		for key, value in pairs(results) do
			assert.are.equal(expected[key], value)
		end
	end)

	it("can JAL, leaves x0 unchanged", function()
		local test_code = {
			"main:",
			"    ADDI x10, x0, 10",
			"    JAL x0, loop3",
			"loop1:",
			"    ADDI x10, x10, 1",
			"    JAL x0, exit",
			"loop2:",
			"    ADDI x10, x10, 1",
			"    JAL x0, loop1",
			"loop3:",
			"    ADDI x10, x10, 1",
			"    JAL x0, loop2",
			"exit: HLT",
		}
		local myCpu = cpu.new(test_code)

		while not myCpu:is_halted() do
			myCpu:step()
		end

		local result = myCpu:get_register("x10")
		local x0 = myCpu:get_register("x0")

		assert.is_true(myCpu:is_halted())
		assert.are.equal(result, 13)
		assert.are.equal(x0, 0)
	end)

	it("can JAL, store return address in register", function()
		local test_code = {
			"main:",
			"    ADDI x10, x0, 10",
			"    JAL x1, loop3",
			"loop1:",
			"    ADDI x10, x10, 1",
			"    JAL x2, exit",
			"loop2:",
			"    ADDI x10, x10, 1",
			"    JAL x3, loop1",
			"loop3:",
			"    ADDI x10, x10, 1",
			"    JAL x4, loop2",
			"exit: HLT",
		}
		local myCpu = cpu.new(test_code)

		while not myCpu:is_halted() do
			myCpu:step()
		end

		local result = myCpu:get_register("x10")
		local x1 = myCpu:get_register("x1")
		local x2 = myCpu:get_register("x2")
		local x3 = myCpu:get_register("x3")
		local x4 = myCpu:get_register("x4")

		assert.is_true(myCpu:is_halted())
		assert.are.equal(result, 13)
		assert.are.equal(x1, 3)
		assert.are.equal(x2, 6)
		assert.are.equal(x3, 9)
		assert.are.equal(x4, 12)
	end)

	it("can BEQ (branch if equal)", function()
		local test_code = {
			"main:",
			"    ADDI x10, x0, 9",
			"    ADDI x11, x0, 9",
			"    BEQ x10, x11, loop1",
			"loop1:",
			"    ADDI x12, x0, 13",
			"    BEQ x10, x12, main",
			"exit: HLT",
		}
		local myCpu = cpu.new(test_code)

		while not myCpu:is_halted() do
			myCpu:step()
		end

		local x10 = myCpu:get_register("x10")
		local x11 = myCpu:get_register("x11")
		local x12 = myCpu:get_register("x12")

		assert.is_true(myCpu:is_halted())
		assert.are.equal(x10, 9)
		assert.are.equal(x11, 9)
		assert.are.equal(x12, 13)
	end)
end)
