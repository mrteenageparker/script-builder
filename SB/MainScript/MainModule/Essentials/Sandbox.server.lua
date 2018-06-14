--[[
	Written by Jacob (@monofur, https://github.com/mrteenageparker)

	Originally modified from my sandbox
	for my discord bot:
	https://github.com/mrteenageparker/sandboxxy

	You are allowed to modify the contents and
	redistribute it, provided you
	keep this above notice and
	republish the original source
	in a way that it is publicly
	available so other people can 
	potentially benefit from your 
	improvements/changes!

	Feel free to read the source of this
	script (including the latest changes)
	on my Github (or create helpful pull 
	requests, if that's your thing!):
	https://github.com/mrteenageparker/sb-in-a-require
]]

-- Globals
local dad_b0x = {} do
	-- Environement
	dad_b0x.mainEnv = getfenv(); -- global env

	-- Pre-defined tables
	dad_b0x.Fake = {
        ['Functions'] = {};
        ['Methods'] = {};

        ['Instances'] = {};
        ['ProtectedInstances'] = {};
	};

    dad_b0x.CachedInstances = {};

	-- Output related shananighans
	dad_b0x.printString = "";

	-- Internalized functions
	dad_b0x.internalFunctions = {
		['wrap'] = (function(obj)
			if dad_b0x.CachedInstances[obj] then
					return dad_b0x.CachedInstances[obj];
			else
				local proxy = newproxy(true);
				getmetatable(proxy).__index = (function(self, index)
					local lIndex = string.lower(index);

					if dad_b0x.Fake.Methods[lIndex] and dad_b0x.Fake.ProtectedInstances[obj.ClassName]
					or dad_b0x.Fake.ProtectedInstances[obj] then
						return (function(...)
							return dad_b0x.Fake.Methods[lIndex](...);
						end);
					else
						if typeof(obj[index]) == "function" then
							return (function(...)
								return obj[index](obj, ...);
							end);
						else
							return dad_b0x.internalFunctions.wrap(obj[index]);
						end;
					end;
				end);
				
				getmetatable(proxy).__metatable = getmetatable(game);

				dad_b0x.CachedInstances[obj] = proxy;

				return proxy;
			end;
	end);
	};

	-- Environments
	dad_b0x.Environments = {
		['level_1'] = setmetatable({},{
			__index = (function(self,index)
				if dad_b0x.Blocked.Instances[index] then
					return nil;
				elseif dad_b0x.Blocked.Functions[index] then
					return dad_b0x.Blocked.Functions[index];
				elseif dad_b0x.Fake.Functions[index] then
					return dad_b0x.Fake.Functions[index];
				elseif dad_b0x.Fake.Instances[index] then
					return dad_b0x.Fake.Instances[index];
				else
					if typeof(dad_b0x.mainEnv[index]) == "Instance" then
							return dad_b0x.internalFunctions.wrap(dad_b0x.mainEnv[index]);
					end;

					return dad_b0x.mainEnv[index];
				end;
			end);

			__metatable = 'Locked. (level_1)';
		}),
	}

	-- Blocked functions
	dad_b0x.Blocked = {
		['Instances'] = {};

		['Functions'] = {
			['require'] = (function(...)
					-- TODO: allow the user to whitelist specific modules
					-- or to straight up disable require()
					return require(...);
				--return error('Attempt to call require() (action has been blocked)', 2)
			end);
			['collectgarbage'] = (function(...)
				return error('Attempt to call collectgarbage() (action has been blocked)', 2);
			end);
		}
	}

	dad_b0x.Fake = {
		['Functions'] = {
			['xpcall'] = (function (luaFunc, handler)
				if type(handler) ~= type(function() end) then
					return error('Bad argument to #1, \'value\' expected', 2);
				else
					local success_func = {pcall(luaFunc)};

					if not success_func[1] then
						local e,r = pcall(handler, success_func[2]);

						if not e then
							return false, 'error in handling';
						end
					end

					return unpack(success_func);
				end
			end);

			['getfenv'] = (function(flevel)
				local s,m = pcall(getfenv, flevel) do
					if not s then
						return error(m, 2);
					else
						if m == dad_b0x.mainEnv then
							return getfenv(0);
						else
							return m;
						end
					end
				end
			end);

			['setfenv'] = (function(f, env)
				local s,m = pcall(getfenv, f);
				if m then
					if m == dad_b0x.mainEnv then
						if type(f) == "function" then
							return error ("'setfenv' cannot change the environment of this function", 2);
						end

						return getfenv(0);
					end
				else
					return error(m, 2)
				end

				local s,m = pcall(setfenv, f, env);

				if not s then
					return error(m, 2);
				end

				return m;
			end);

			['print'] = (function(...)
				-- TODO: hook the print object
				return print(...);
			end);
		};

		['Instances'] = {
			['debug'] = {
				['traceback'] = debug.traceback;
			};

			['os'] = {
				['time'] = os.time,
				['difftime'] = os.difftime,
				['date'] = os.date,
			};

			['_G'] = {}; -- TODO: sync with server table
		};

		['Methods'] = {
			['destroy'] = (function(...)
				return error("Object is locked.", 3);
			end);
		};
		['ProtectedInstances'] = {
			-- TODO: add the ability to make custom
			-- protected objects, however the default
			-- should be all the SB components.
			[workspace.Baseplate] = true;
		};
	};
end;

-- Set the rest of the environment
setfenv(0, dad_b0x.Environments.level_1);
setfenv(1, dad_b0x.Environments.level_1);

local function exec(src)
	local s,m = loadstring(src, 'SB-Script');
	if not s then
		return error(m, 0);
	else
		return setfenv(s, dad_b0x.Environments.level_1)();
	end;
end;

exec([[
	workspace.Baseplate:Destroy()
]]);