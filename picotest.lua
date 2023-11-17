local public = {}

function public.assert_equals(expected, actual)
	if expected ~= actual then
		error("expected '" .. expected .. "', got '" .. actual .. "'")
	end
end

local function walk_tests_gen(t, prefix)
	for k, v in pairs(t) do
		local path = prefix and (prefix .. "." .. k) or k
		if type(v) == "function" then
			coroutine.yield(path, v)
		elseif type(v) == "table" then
			walk_tests_gen(v, path)
		else
			error("Unexpected value found in tests object (" .. path .. ")")
		end
	end
end

local function walk_tests(t)
	return coroutine.wrap(function()
		walk_tests_gen(t)
	end)
end

function public.tests(t)
	local results = {}

	for test_name, test_fn in walk_tests(t) do
		local success, err = pcall(test_fn)
		table.insert(results, {
			name = test_name,
			passed = success,
			message = err,
		})

		io.write(success and "." or "\027[31mF\027[m")
		io.flush()
	end

	local num_tests = #results
	local num_passed = 0
	local num_failed = 0
	for _, result in ipairs(results) do
		if result.passed then
			num_passed = num_passed + 1
		else
			num_failed = num_failed + 1
			io.write("\n\n\027[1m#" .. num_failed .. "\027[m  In '" .. result.name .. "': " .. result.message)
		end
	end

	local ansi_colour = num_failed == 0 and 32 or 31
	io.write(
		"\n\n\027["
			.. ansi_colour
			.. ";1m"
			.. num_tests
			.. " tests, "
			.. num_passed
			.. " passed, "
			.. num_failed
			.. " failed.\027[m\n"
	)
end

return public
