--[[
    TownManagerSummary.lua

    Summary menu that displays the town map.
]]

TownManagerSummary = Class("TownManagerSummary")

function TownManagerSummary:initialize()
    self.selecting = false

    local asset_id = _HUB.getHubPlotMap()
    local object = RogueEssence.Content.AnimData(asset_id, 1)
    local sheet = RogueEssence.Content.GraphicsManager.GetObject(asset_id)

    local w = 164
    local h = sheet.Height + Graphics.Manager.MenuBG.TileHeight*3 + Graphics.VERT_SPACE
    local x = Graphics.Manager.ScreenWidth - 16 - w
    local y = 16
    self.window = RogueEssence.Menu.SummaryMenu(RogueElements.Rect(x, y, w, h))

    self.offset_x = (self.window.Bounds.Width-sheet.Width)//2
    self.offset_y = Graphics.Manager.MenuBG.TileHeight --(self.window.Bounds.Width-Graphics.VERT_SPACE-sheet.Height)//2

    self.map = RogueEssence.Menu.MenuDirTex(RogueElements.Loc(self.offset_x,self.offset_y), RogueEssence.Menu.MenuDirTex.TexType.Object, object)
    self.window.Elements:Add(self.map)

    local cursor_object =   RogueEssence.Content.AnimData("map_cursor",   1, 1, 1)
    local cursor_object_b = RogueEssence.Content.AnimData("map_cursor_b", 1, 1, 1)
    self.cursorFrameDur = 24
    self.cursorTickOffset = 0
    self.cursor =   RogueEssence.Menu.MenuDirTex(RogueElements.Loc(self.offset_x,self.offset_y), RogueEssence.Menu.MenuDirTex.TexType.Object, cursor_object)
    self.cursor_b = RogueEssence.Menu.MenuDirTex(RogueElements.Loc(self.offset_x,self.offset_y), RogueEssence.Menu.MenuDirTex.TexType.Object, cursor_object_b)

    self.plot_tokens = self:LoadPlotData()
    for _, token in pairs(self.plot_tokens) do
        self.window.Elements:Add(token)
    end

    self.title = RogueEssence.Menu.MenuText("", RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - Graphics.VERT_SPACE))
    self.level = RogueEssence.Menu.MenuText("", RogueElements.Loc(self.window.Bounds.Width - Graphics.Manager.MenuBG.TileWidth*2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - Graphics.VERT_SPACE), RogueElements.DirH.Right)
    self.window.Elements:Add(self.title)
    self.window.Elements:Add(self.level)
end

function TownManagerSummary:LoadPlotData()
    local plots = {}
    local plotNumber = _HUB.getRankPlotNumber()
    for i = 1, plotNumber, 1 do
        local pos = _HUB.getPlotMarkerOrigin(i)
        local plot = SV.HubData.Plots[i]
        local asset_id = "map_token_empty"
        if not plot.unlocked then
            asset_id = "map_token_locked"
        elseif plot.building ~= "" then
            asset_id = "map_token_"..plot.building
        end
        local object = RogueEssence.Content.AnimData(asset_id, 1)
        local token = RogueEssence.Menu.MenuDirTex(RogueElements.Loc(self.offset_x + pos.X, self.offset_y + pos.Y), RogueEssence.Menu.MenuDirTex.TexType.Object, object)
        table.insert(plots, token)
    end
    return plots
end

function TownManagerSummary:SelectTown()
    self.title:SetText(_HUB.getHubName())
    self.level:SetText(STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT")..tostring(_HUB.getHubLevel()))
    self.title.Loc = RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - Graphics.VERT_SPACE)
    self.title.AlignH = RogueElements.DirH.Left
    self.window.Elements:Remove(self.cursor)
    self.selecting = false
end

function TownManagerSummary:HideSilverCursor()
    self.window.Elements:Remove(self.cursor_b)
    self.selecting_b = true
end

function TownManagerSummary:UpdateCursor()
    if not self.selecting then return end
    if ((Graphics.Manager.TotalFrameTick - self.cursorTickOffset) // RogueEssence.FrameTick.FrameToTick(self.cursorFrameDur // 2)) % 2 == 0 then
        self.cursor.Anim.StartFrame = 0
        self.cursor.Anim.EndFrame = 0
        self.cursor_b.Anim.StartFrame = 1
        self.cursor_b.Anim.EndFrame = 1
    else
        self.cursor.Anim.StartFrame = 1
        self.cursor.Anim.EndFrame = 1
        self.cursor_b.Anim.StartFrame = 0
        self.cursor_b.Anim.EndFrame = 0
    end
end

function TownManagerSummary:SetSilverCursorToPlot(index)
    local pos = _HUB.getPlotMarkerOrigin(index)
    if not self.selecting_b then
        self.window.Elements:Add(self.cursor_b)
        self.selecting_b = true
    end
    self.cursor_b.Loc = RogueElements.Loc(self.offset_x + pos.X -3, self.offset_y + pos.Y -3)
end

function TownManagerSummary:SelectPlot(index, skip_cursor_offset)
    local plot = _HUB.getPlotData(index)
    local title = STRINGS:FormatKey("SHOP_NAME_EMPTY")
    local level = ""
    if plot.building ~= "" then
        local shopkeeper_name = _DATA:GetMonster(plot.shopkeeper.species):GetColoredName()
        title = STRINGS:FormatKey("SHOP_NAME_"..string.upper(plot.building), shopkeeper_name)
        level = STRINGS:FormatKey("MENU_TEAM_LEVEL_SHORT")..tostring(_HUB.getPlotLevel(plot))
    end
    self.title:SetText(title)
    self.level:SetText(level)
    if level == "" then
        self.title.Loc = RogueElements.Loc(self.window.Bounds.Width//2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - Graphics.VERT_SPACE)
        self.title.AlignH = RogueElements.DirH.None
    else
        self.title.Loc = RogueElements.Loc(Graphics.Manager.MenuBG.TileWidth*2, self.window.Bounds.Height - Graphics.Manager.MenuBG.TileHeight - Graphics.VERT_SPACE)
        self.title.AlignH = RogueElements.DirH.Left
    end
    if not self.selecting then
        self.window.Elements:Add(self.cursor)
        self.selecting = true
    end
    local pos = _HUB.getPlotMarkerOrigin(index)
    self.cursor.Loc = RogueElements.Loc(self.offset_x + pos.X -3, self.offset_y + pos.Y -3)
    if not skip_cursor_offset then self:RefreshCursor() end
end

function TownManagerSummary:RefreshCursor()
    self.cursorTickOffset = Graphics.Manager.TotalFrameTick % RogueEssence.FrameTick.FrameToTick(self.cursorFrameDur)
end