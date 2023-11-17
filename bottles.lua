require("stdlib")

local CountdownSong
local BottleNumber
local BottleVerse

CountdownSong = {
	new = function(self, params)
		params = params or {}
		return extends(self, {
			verse_template = params.verse_template or BottleVerse,
			max = params.max or 999999,
			min = params.min or 0,
		})
	end,

	song = function(self)
		return self:verses(self.max, self.min)
	end,

	verses = function(self, upper, lower)
		local result = ""
		for i = upper, lower, -1 do
			result = result .. self:verse(i) .. "\n"
		end
		return string.sub(result, 1, -2)
	end,

	verse = function(self, number)
		return self.verse_template.lyrics_for(number)
	end,
}

BottleVerse = {
	lyrics_for = function(number)
		return BottleVerse:new(BottleNumber.from_int(number)):lyrics()
	end,

	new = function(self, bottle_number)
		return extends(self, { bottle_number = bottle_number })
	end,

	lyrics = function(self)
		return string.capitalize(self.bottle_number:to_string() .. " of beer on the wall, ")
			.. self.bottle_number:to_string()
			.. " of beer.\n"
			.. self.bottle_number:action()
			.. ", "
			.. self.bottle_number:successor():to_string()
			.. " of beer on the wall.\n"
	end,
}

BottleNumber = {
	class_name = "BottleNumber",

	to_string = function(self)
		return self:quantity() .. " " .. self:container()
	end,

	container = function(_self)
		return "bottles"
	end,

	pronoun = function(_self)
		return "one"
	end,

	quantity = function(self)
		return self.number
	end,

	action = function(self)
		return "Take " .. self:pronoun() .. " down and pass it around"
	end,

	successor = function(self)
		return BottleNumber.from_int(self.number - 1)
	end,

	subclasses = {},
	subclass = function(self, name, decl)
		local subclass = extends(self, decl)
		subclass.class_name = name
		table.insert(self.subclasses, subclass)
		return subclass
	end,
}

BottleNumber:subclass("BottleNumber0", {
	handles = 0,

	quantity = function(_self)
		return "no more"
	end,

	action = function(_self)
		return "Go to the store and buy some more"
	end,

	successor = function(_self)
		return BottleNumber.from_int(99)
	end,
})

BottleNumber:subclass("BottleNumber1", {
	handles = 1,

	container = function(_self)
		return "bottle"
	end,

	pronoun = function(_self)
		return "it"
	end,
})

BottleNumber:subclass("BottleNumber6", {
	handles = 6,

	container = function(_self)
		return "six-pack"
	end,

	quantity = function(_self)
		return 1
	end,
})

function BottleNumber.from_int(number)
	local function is_handled_by(subclass)
		if subclass.handles == nil then
			error(subclass.class_name .. " doesn't define a handles() method")
		end

		if type(subclass.handles) == "function" then
			return subclass.handles(number)
		else
			return subclass.handles == number
		end
	end

	for _, subclass in ipairs(BottleNumber.subclasses) do
		if is_handled_by(subclass) then
			return extends(subclass, { number = number })
		end
	end

	return extends(BottleNumber, { number = number })
end

if os.getenv("TEST") then
	local pico = require("picotest")

	local VerseFake = {
		lyrics_for = function(number)
			return "This is verse " .. number .. ".\n"
		end,
	}

	pico.tests({
		CountdownSong = {
			song = function()
				local expected = "This is verse 99.\n\nThis is verse 98.\n\nThis is verse 97.\n"
				pico.assert_equals(
					expected,
					CountdownSong:new({ verse_template = VerseFake, max = 99, min = 97 }):song()
				)
			end,

			verses = function()
				local expected =
					"This is verse 47.\n\nThis is verse 46.\n\nThis is verse 45.\n\nThis is verse 44.\n\nThis is verse 43.\n"
				pico.assert_equals(expected, CountdownSong:new({ verse_template = VerseFake }):verses(47, 43))
			end,

			verse = function()
				local expected = "This is verse 13.\n"
				pico.assert_equals(expected, CountdownSong:new({ verse_template = VerseFake }):verse(13))
			end,
		},

		BottleVerse = {
			lyrics_for_generic_upper_bound = function()
				local expected = "99 bottles of beer on the wall, 99 bottles of beer.\n"
					.. "Take one down and pass it around, 98 bottles of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(99))
			end,

			lyrics_for_generic_lower_bound = function()
				local expected = "3 bottles of beer on the wall, 3 bottles of beer.\n"
					.. "Take one down and pass it around, 2 bottles of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(3))
			end,

			lyrics_for_7_uses_sixpack = function()
				local expected = "7 bottles of beer on the wall, 7 bottles of beer.\n"
					.. "Take one down and pass it around, 1 six-pack of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(7))
			end,

			lyrics_for_6_uses_sixpack = function()
				local expected = "1 six-pack of beer on the wall, 1 six-pack of beer.\n"
					.. "Take one down and pass it around, 5 bottles of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(6))
			end,

			lyrics_for_2_uses_singular_bottle = function()
				local expected = "2 bottles of beer on the wall, 2 bottles of beer.\n"
					.. "Take one down and pass it around, 1 bottle of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(2))
			end,

			lyrics_for_1_uses_singular_bottle_and_it_pronoun = function()
				local expected = "1 bottle of beer on the wall, 1 bottle of beer.\n"
					.. "Take it down and pass it around, no more bottles of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(1))
			end,

			lyrics_for_0_uses_no_more_and_special_action = function()
				local expected = "No more bottles of beer on the wall, no more bottles of beer.\n"
					.. "Go to the store and buy some more, 99 bottles of beer on the wall.\n"
				pico.assert_equals(expected, BottleVerse.lyrics_for(0))
			end,
		},

		BottleNumber = {
			to_string = function()
				pico.assert_equals("55 bottles", BottleNumber.from_int(55):to_string())
				pico.assert_equals("1 bottle", BottleNumber.from_int(1):to_string())
				pico.assert_equals("no more bottles", BottleNumber.from_int(0):to_string())
				pico.assert_equals("1 six-pack", BottleNumber.from_int(6):to_string())
			end,

			action = function()
				pico.assert_equals("Take one down and pass it around", BottleNumber.from_int(55):action())
				pico.assert_equals("Take it down and pass it around", BottleNumber.from_int(1):action())
				pico.assert_equals("Go to the store and buy some more", BottleNumber.from_int(0):action())
			end,
		},
	})

	return
end

print(CountdownSong:new({ max = 99, min = 0 }):song())
