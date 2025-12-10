require("Starlit/utils/Reflection")
require("Starlit/VanillaEvents")

-- ensure compatibility with Immersive Medicine by not letting it (accidentally?) overwrite the global Trait
local Trait = Trait
require("Component/Trait/Entity/Trait")
_G["Trait"] = Trait
