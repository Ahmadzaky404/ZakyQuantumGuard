local Scripts = {
    [994732206] = "https://raw.githubusercontent.com/Ahmadzaky404/ZakyQuantumGuard/main/Games/BloxFruits_CleanPatch.lua",
    [9186719164] = "https://raw.githubusercontent.com/Ahmadzaky404/ZakyQuantumGuard/main/Games/SailorPiece.lua",
}

local url = Scripts[game.GameId]
if url then
    loadstring(game:HttpGet(url))()
end
