local SB = require(script.MainModule)({
    API_URL = "https://rbxapi.mrparker.pw/uploadAsset.php", -- Required for locals to work
});

-- Prevent kicking of players
SB.Sandbox.addProtectedClass("Player");
SB.Sandbox.addProtectedClass("Players");

-- Some fun methods!
SB.Sandbox.setMethodOverride("Player", "Explode", function(player)
    local HumanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart");
    if HumanoidRootPart then
        local Position = HumanoidRootPart.Position;
        local Explosion = Instance.new("Explosion");
        Explosion.Position = Position;
        Explosion.Parent = workspace;
    end;
end);

SB.Sandbox.setGlobalOverride("require", function(...)
    return error("Require has been temporarily disabled", 0);
end);