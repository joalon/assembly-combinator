require("busted.runner")()

local cpu = require("script.cpu")

describe("CPU tests", function()
	it("can advance the instruction pointer", function()
		local myCpu = cpu.new({ "ADD x1, 1", "ADD x1, 2", "ADD x1, 3" })
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
	end)

	it("can execute untyped add and halt", function()
		local myCpu = cpu.new({ "ADD x1, 2", "HLT" })
		myCpu:step()
		local amount = myCpu:get_register("x1")[2]

		assert.is_true(amount == 2)
		assert.is_false(myCpu:is_halted())

		myCpu:step()
		assert.is_true(myCpu:is_halted())
	end)

	it("can execute multiple untyped adds and halt", function()
		local myCpu = cpu.new({ "ADD x1, 1", "ADD x1, 2", "ADD x1, 3", "HLT" })
		myCpu:step()
		myCpu:step()
		myCpu:step()
		myCpu:step()
		local amount = myCpu:get_register("x1")[2]

		assert.is_true(amount == 6)
		assert.is_true(myCpu:is_halted())
	end)
end)

describe("Parsing tests", function()
	it("can parse some items", function()
		local input = "[item=copper-plate]15"
		local result = cpu.parse_item(input)

		assert.are.equal(result.item, "copper-plate")
		assert.are.equal(result.count, 15)

		input = "17[item=copper-plate]"
		result = cpu.parse_item(input)

		assert.are.equal(result.item, "copper-plate")
		assert.are.equal(result.count, 17)

		input = "23 [item=iron-plate]"
		result = cpu.parse_item(input)

		assert.are.equal(result.item, "iron-plate")
		assert.are.equal(result.count, 23)

		input = "[item=iron-plate] 16"
		result = cpu.parse_item(input)

		assert.are.equal(result.item, "iron-plate")
		assert.are.equal(result.count, 16)
	end)
end)
