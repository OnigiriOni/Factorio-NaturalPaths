-- Jetpack mod

-- The mod changes the character prototype that the player is using and appends a "-jetpack" to its name while flying.

-- Returns true if the player character is flying with a jetpack and does not touch the ground.
function isPlayerUsingJetpack(player)
    return player.character and string.find(player.character.name, "-jetpack") or false
end