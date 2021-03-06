--[[
	Written by Jacob (mrparkerlol on Github), with contributions by others.

	This is the server script source for the Script Builder Project,
	licensed GPL V3 only.

	This is provided free of charge, no warranty or liability
	provided. Use of this project is at your own risk.

	Documentation is also provided on Github, if needed.
]]

local game = game;
local workspace = workspace;
local Instance = Instance;

local Debris = game:GetService("Debris");
local InsertService = game:GetService("InsertService");

local spawn = spawn;
local getfenv = getfenv;
local loadstring = loadstring;
local shared = shared;
local setfenv = setfenv;
local typeof = typeof;

-- Metatable for "shared" already is locked, however
-- the main script is using .SB for the SB, use
-- that instead.
if getmetatable(shared) ~= nil and shared.SB then
	shared = shared.SB;
end;

-- Get the owner of the script and source.
local config = shared(script);

-- Require the sandbox
local sandbox = shared("Sandbox");

spawn(function()
	-- Create the sandbox instance
	-- Print, warn and _G and shared sandboxing
	-- is done for you
	local sandboxInstance = sandbox.new(script, getfenv());

	sandboxInstance.setLocalOverride("warn", function(...)
		-- Make the args a table
		local args = {...};

		-- Iterate through the arguments, convert them to a string
		for i=1, #args do
			args[i] = tostring(args[i]);
		end;

		-- Concatenate the strings together,
		-- using a space as a delimiter
		local printString = table.concat(args, " ");

		-- Send the string to the output
		shared("Output", {
			Owner = config.Owner,
			Type = "warn",
			Message = printString
		});
	end);

	sandboxInstance.setLocalOverride("print", function(...)
		-- Make the args a table
		local args = {...};

		-- Iterate through the arguments, convert them to a string
		for i=1, #args do
			args[i] = tostring(args[i]);
		end;

		-- Concatenate the strings together,
		-- using a space as a delimiter
		local printString = table.concat(args, " ");

		-- Send the string to the output
		shared("Output", {
			Owner = config.Owner,
			Type = "print",
			Message = printString
		});
	end);

	sandboxInstance.setLocalOverride("NS", function(source, parent)
		return sandbox.wrap(sandboxInstance, shared("runScript", source, sandbox.getReal(sandboxInstance, parent) or nil, config.Owner));
	end);

	sandboxInstance.setLocalOverride("NLS", function(source, parent)
		return sandbox.wrap(sandboxInstance, shared("runLocal", source, sandbox.getReal(sandboxInstance, parent) or nil, config.Owner));
	end);

	sandboxInstance.setLocalOverride("typeof", function(object)
		local real = sandbox.getReal(sandboxInstance, object);
		return typeof(real);
	end);

	sandboxInstance.setLocalOverride("type", function(object)
		local real = sandbox.getReal(sandboxInstance, object);
		return type(real);
	end);

	sandboxInstance.setLocalOverride("game", sandbox.wrap(sandboxInstance, game));
	sandboxInstance.setLocalOverride("Game", sandbox.wrap(sandboxInstance, game));

	sandboxInstance.setLocalOverride("workspace", sandbox.wrap(sandboxInstance, workspace));
	sandboxInstance.setLocalOverride("Workspace", sandbox.wrap(sandboxInstance, workspace));
	sandboxInstance.setLocalOverride("script", sandbox.wrap(sandboxInstance, script));
	sandboxInstance.setLocalOverride("owner", sandbox.wrap(sandboxInstance, config.Owner));
	sandbox.setCustomProperty("Script", "owner", config.Owner);

	sandboxInstance.setLocalOverride("Instance", setmetatable({
		new = (function(class, parent)
			parent = sandbox.getReal(sandboxInstance, parent);
			if typeof(class) ~= "string" then
				return error("invalid argument #1 to 'new' (string expected, got " .. typeof(class) .. ")", 2);
			elseif typeof(parent) ~= "Instance" and parent ~= nil then
				return error("invalid argument #2 to 'new' (Instance expected, got " .. typeof(parent) .. ")", 2);
			end;

			local success, object = pcall(Instance.new, class, parent);
			if success then
				table.insert(sandbox.CreatedInstances, object);
			else
				return error(object, 2);
			end;

			return sandbox.wrap(sandboxInstance, object);
		end),
	}, {
		__newindex = (function(self, ...) return error("Attempt to modify a readonly table", 2); end),
		__metatable = "The metatable is locked",
	}));

	sandbox.setMethodOverride("InsertService", "LoadAsset", function(self, assetid)
		local success, model = pcall(InsertService.LoadAsset, InsertService, assetid);
		if success then
			-- Add to created instances
			table.insert(sandbox.CreatedInstances, model);

			-- Return the model/object
			return sandbox.wrap(sandboxInstance, model);
		else
			return error(model, 2);
		end;
	end);

	sandbox.setMethodOverride("InsertService", "LoadAssetVersion", function(self, assetVersion)
		local success, model = pcall(InsertService.LoadAssetVersion, InsertService, assetVersion);
		if success then
			-- Add to created instances
			table.insert(sandbox.CreatedInstances, model);

			-- Return the model/object
			return sandbox.wrap(sandboxInstance, model);
		else
			return error(model, 2);
		end;
	end);

	sandbox.setMethodOverride("Debris", "AddItem", function(self, object, time)
		if typeof(object) ~= "Instance" then
			return error("Unable to cast value to Object", 3);
		end;

		if sandbox.ProtectedClasses[object.ClassName] then
			return error(object.ClassName .. " is protected", 3);
		elseif not sandbox.PreventAccess[object] then
			return Debris:AddItem(sandbox.getReal(sandboxInstance, object), time);
		end;
	end);

	--[[sandboxInstance.setLocalOverride("require", function(asset)
		if typeof(asset) == "number" then
			return error("Require has been temporarily disabled", 0);
		else
			return require(sandbox.getReal(sandboxInstance, asset));
		end;
	end);]]

	local Function, message = loadstring(config.Source, 'SB-Script');
	if not Function then
		-- Code had a syntax error
		return error(message, 0);
	else
		shared("Output", {
			Owner = config.Owner,
			Type = "general",
			Message = "Ran server script."
		});

		-- Run the code inside the sandbox
		local environment = sandboxInstance.environment;
		setfenv(0, environment);
		setfenv(1, environment);
		setfenv(Function, environment)();
	end;
end);