local config = require("Starlit/client/internal/config")
local ZombieDataDebugger = require("Starlit/client/debug/ZombieDataDebugger")

local UI = PZAPI.UI

local items = {
    ["IGUI_StarlitLibrary_ZombieDataDebugger"] = ZombieDataDebugger
}

-- global instance of the ui, to make sure we don't open it twice
---@type UI.Node | nil
local instance = nil

local DebugMenu = UI.Window{
    x = 100, y = 100,
    width = 256, height = 512,
    children = {
        body = UI.Window.children.body{
            children = {
                container = UI.Node{
                    anchorLeft = 0, anchorRight = -10,
                    children = {},
                    init = function(self)
                        self.parent.children.scrollBar.container = self
                        local numChildren = 0
                        for name, item in pairs(items) do
                            self.children[name] = UI.TextButton{
                                y = numChildren * 69,
                                height = 64,
                                anchorLeft = 10, anchorRight = -10,
                                children = {
                                    label = UI.Text{
                                        anchorLeft = 0, anchorRight = 0,
                                        anchorTop = 0, anchorDown = 0,
                                        pivotX = 0.5, pivotY = 0.5,
                                        text = getText(name)
                                    }
                                },
                                onLeftClick = function(self)
                                    local itemInstance = item{}
                                    itemInstance:instantiate()
                                    if instance then
                                        UIManager.RemoveElement(instance.javaObj)
                                        instance = nil
                                    end
                                end
                            }
                            numChildren = numChildren + 1
                            UI._addChild(self, self.children[name])
                        end
                        self:setHeight(numChildren * 69)
                        self:onResize()
                    end,
                    onResize = function(self)
                        self.parent.children.scrollBar:setBarSize(self.parent.height / (self.height))
                        self.parent.children.scrollBar:updateBar(0)
                    end,
                    onScroll = function(self, percent)
                        self.parent.children.scrollBar:updateBar(percent)
                    end,
                },
                scrollBar = UI.ScrollBarVertical{}
            }
        }
    }
}

---@type Callback_OnKeyPressed
local function openDebugMenu(key)
    if not isIngameState() then
        return
    end
    if key == config.keys.openDebugMenu then
        if instance then
            UIManager.RemoveElement(instance.javaObj)
            instance = nil
        end
        instance = DebugMenu{}
        instance:instantiate()
    end
end

Events.OnKeyPressed.Add(openDebugMenu)
