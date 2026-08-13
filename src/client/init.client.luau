--!strict
--[[
    Client bootstrap — Phase 0 exit exercise.

    Four sounds on four keys. Proves the Rojo sync loop, AudioGraph, and
    UserInputService key handling all work together before anything else gets
    built on top of them. See ROADMAP.md Phase 0 and SETUP.md "First task".

    Transport isn't exercised here on purpose — nothing in this exercise loops
    or needs a clock. It gets its first real workout driving the step grid in
    Phase 1.
]]

local UserInputService = game:GetService("UserInputService")

local AudioGraph = require(script.AudioGraph)

local KEY_TRACKS = {
    [Enum.KeyCode.Z] = { index = 1, assetId = "rbxassetid://137721550021975", name = "kick" },
    [Enum.KeyCode.X] = { index = 2, assetId = "rbxassetid://111706213677417", name = "snare" },
    [Enum.KeyCode.C] = { index = 3, assetId = "rbxassetid://104860520282914", name = "closed hat" },
    [Enum.KeyCode.V] = { index = 4, assetId = "rbxassetid://125077204312772", name = "open hat" },
}

local graph = AudioGraph.new(script)

for _, track in KEY_TRACKS do
    graph:CreateTrack(track.index, track.assetId)
end

graph:Warm()

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then
        return
    end

    local track = KEY_TRACKS[input.KeyCode]
    if track then
        graph:PlayNote(track.index)
    end
end)
