local UI = PZAPI.UI

local gridItem = UI.Panel{
    height = 64,
    anchorLeft = 20, anchorRight = -20,
    children = {
        label = UI.Text{
            pivotX = 0.5, pivotY = 0.5,
            scaleX = 0.5, scaleY = 0.5,
            anchorRight = 0, anchorLeft = 0, anchorTop = 0, anchorDown = 0
        }
    },
}

local zombieDataContainer = UI.Node{
    isStencil = true,
    anchorLeft = 250, anchorRight = 0,
    anchorTop = 0, anchorDown = 0,
    data = {},
    children = {
        container = UI.Node{
            anchorLeft = 0, anchorRight = -10,
            children = {
                keys = UI.Node{
                    anchorLeft = 0,
                    children = {
                        label = UI.Text{
                            y = 15,
                            anchorLeft = 0, anchorRight = 0,
                            pivotX = 0.5,
                            text = "Key"
                        }
                    }
                },
                values = UI.Node{
                    anchorRight = 0,
                    children = {
                        label = UI.Text{
                            y = 15,
                            anchorLeft = 0, anchorRight = 0,
                            pivotX = 0.5,
                            text = "Value"
                        }
                    }
                }
            },
            init = function(self)
                self.parent.children.scrollBar.container = self
                local numChildren = 0
                for k, v in pairs(self.parent.data) do
                    self.children.keys[k] = gridItem{
                        y = 60 + numChildren * 69,
                        children = {
                            label = gridItem.children.label{
                                text = k
                            }
                        }
                    }
                    UI._addChild(self.children.keys, self.children.keys[k])

                    self.children.values[k] = gridItem{
                        y = 60 + numChildren * 69,
                        children = {
                            label = gridItem.children.label{
                                text = v
                            }
                        }
                    }
                    UI._addChild(self.children.values, self.children.values[k])

                    numChildren = numChildren + 1
                end
            end,
            onResize = function(self)
                self.parent.children.scrollBar:setBarSize(self.parent.height / (self.height))
                self.parent.children.scrollBar:updateBar(0)
                self.children.keys:setWidth(self.width / 2)
                self.children.values:setWidth(self.width / 2)
            end,
            onScroll = function(self, percent)
                self.parent.children.scrollBar:updateBar(percent)
            end,
        },
        scrollBar = UI.ScrollBarVertical{}
    }
}

local zombieIDButton = UI.TextButton{
    x = 0,
    zombieId = 0,
    height = 40,
    anchorLeft = 0, anchorRight = 0,
    children = {
        label = UI.TextButton.children.label{}
    },
    init = function(self)
        self.children.label:setText(tostring(self.zombieId))
        UI.TextButton.init(self)
    end,
    onLeftClick = function(self)
        local body = self.parent.parent.parent
        local zombieData = body.children.zombieData
        if zombieData then
            zombieData.javaObj:getParentNode():removeNode(zombieData.javaObj)
        end
        body.children.zombieData = zombieDataContainer{
            data = ModData.get("starlit.ZombieData")[self.zombieId]
        }
        UI._addChild(body, body.children.zombieData)
    end
}

local ZombieDataDebugger = UI.Window{
    x = 100, y = 100,
    width = 1200, height = 600,
    children = {
        body = UI.Window.children.body{
            children = {
                zombieIdList = UI.Node{
                    isStencil = true,
                    width = 250,
                    anchorLeft = 0,
                    anchorTop = 0, anchorDown = 0,
                    children = {
                        container = UI.Node{
                            anchorRight = -10,
                            children = {},
                            init = function(self)
                                self.parent.children.scrollBar.container = self
                                local numChildren = 0
                                for id, _ in pairs(ModData.get("starlit.ZombieData")) do
                                    -- ignore special string keys
                                    if type(id) == "number" then
                                        self.children[id] = zombieIDButton{
                                            y = numChildren * 40,
                                            zombieId = id
                                        }
                                        UI._addChild(self, self.children[id])
                                        numChildren = numChildren + 1
                                    end
                                end
                                self:setHeight(numChildren * 40)
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
            },
        },
    }
}

return ZombieDataDebugger