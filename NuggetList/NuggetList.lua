local addonName = ...
local _G = _G

local function Media(path) return "Interface\\AddOns\\NuggetList\\Media\\" .. path end
local PANEL_BG = Media("bg.tga")
local EDIT_BORDER = Media("edit_border.tga")
local BUTTON_NORMAL = Media("button.tga")
local BUTTON_HOVER = Media("button_hover.tga")
local SCROLL_TRACK = Media("scrollbar_track.tga")
local SCROLL_THUMB = Media("scrollbar_thumb.tga")
local FONT = GameFontNormal:GetFont() 
local TITLE_FONT_SIZE = 14
local BODY_FONT_SIZE = 12
local LIGHT_TEXT = {0.9, 0.9, 0.9}
local DIM_TEXT = {0.67, 0.67, 0.67}
local ACCENT = {0.11, 0.58, 0.86}


local function ApplyPanelSkin(frame)
    frame:SetBackdrop({
        bgFile = PANEL_BG,
        edgeFile = PANEL_BORDER,
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    frame:SetBackdropColor(0.07, 0.08, 0.10, 0.95)
    frame:SetBackdropBorderColor(0.05, 0.06, 0.07)
	
    if not frame._nug_shadow then
        local sh = frame:CreateTexture(nil, "BACKGROUND")
        sh:SetTexture(SHADOW)
        sh:SetPoint("TOPLEFT", -6, 6)
        sh:SetPoint("BOTTOMRIGHT", 6, -6)
        sh:SetBlendMode("BLEND")
        sh:SetAlpha(0.45)
        frame._nug_shadow = sh
    end
end

local function CreateButton(parent, width, height, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 80, height or 24)

    local tex = b:CreateTexture(nil, "BACKGROUND")
    tex:SetTexture(BUTTON_NORMAL)
    tex:SetAllPoints(b)
    b._nug_tex = tex

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetTexture(BUTTON_HOVER)
    hover:SetAllPoints(b)
    hover:SetBlendMode("ADD")
    b._nug_hover = hover

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("CENTER")
    b.text:SetFont(FONT, BODY_FONT_SIZE)
    b.text:SetText(text or "Button")
    b.text:SetTextColor(unpack(LIGHT_TEXT))

    b:SetScript("OnMouseDown", function(self) self._nug_tex:SetPoint("TOPLEFT", 1, -1) end)
    b:SetScript("OnMouseUp", function(self) self._nug_tex:SetPoint("TOPLEFT", 0, 0) end)

    return b
end

local function CreateEditBox(parent, width, height, initial)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetAutoFocus(false)
    eb:SetMultiLine(false)
    eb:SetSize(width or 120, height or 20)
    eb:SetFont(FONT, BODY_FONT_SIZE)
    eb:SetText(initial or "")
    eb:SetBackdrop({
        bgFile = EDIT_BG,
        edgeFile = EDIT_BORDER,
        tile = false, tileSize = 0, edgeSize = 2,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    eb:SetBackdropColor(0.08, 0.09, 0.10, 1)
    eb:SetTextColor(unpack(LIGHT_TEXT))
    return eb
end

local function SkinScrollBar(scrollFrame)
    if not scrollFrame then return end
    local scrollbar = scrollFrame.ScrollBar
    if not scrollbar then return end

    scrollbar:GetThumbTexture():SetTexture(nil)

    if not scrollbar._nug_track then
        local track = scrollbar:CreateTexture(nil, "BACKGROUND")
        track:SetTexture(SCROLL_TRACK)
        track:SetAllPoints(scrollbar)
        scrollbar._nug_track = track
    end

    if not scrollbar._nug_thumb then
        local thumb = CreateFrame("Frame", nil, scrollbar)
        thumb:SetSize(12, 32)
        thumb.tex = thumb:CreateTexture(nil, "ARTWORK")
        thumb.tex:SetAllPoints()
        thumb.tex:SetTexture(SCROLL_THUMB)
        scrollbar._nug_thumb = thumb
    end

    scrollbar:HookScript("OnUpdate", function(self)
        local scrollChild = scrollFrame:GetScrollChild()
        if not scrollChild then return end

        local offset = scrollFrame:GetVerticalScroll()
        local min, max = self:GetMinMaxValues()
        local thumbHeight = self._nug_thumb:GetHeight()
        local trackHeight = self:GetHeight() - thumbHeight
        local pct = (offset - min) / max
        self._nug_thumb:SetPoint("TOPLEFT", 0, -pct * trackHeight)
    end)
end

SkinScrollBar(_G.NuggetListScrollFrame)

local frame = CreateFrame("Frame", "NuggetListFrame", UIParent)
frame:SetSize(400, 450)
frame:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
ApplyPanelSkin(frame)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetPoint("TOP", -16, -20)
frame.title:SetFont(FONT, TITLE_FONT_SIZE)
frame.title:SetText("NiggerList v0.2")

local scrollFrame = CreateFrame("ScrollFrame", "NuggetListScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 22, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

local content = CreateFrame("Frame", "NuggetListContent", scrollFrame)
content:SetWidth(370)
content:SetHeight(1)
scrollFrame:SetScrollChild(content)
frame.content = content
frame.entries = {}
local activeTextWindow = nil

SkinScrollBar(_G.NuggetListScrollFrameScrollBar)

local modeToggleButton = CreateButton(frame, 100, 26, "Whitelist")
modeToggleButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)

local listMode = "whitelist"
local function UpdateModeButton()
    if listMode == "blacklist" then
        modeToggleButton.text:SetText("Blacklist")
        modeToggleButton.text:SetTextColor(1, 0.35, 0.35)
    else
        modeToggleButton.text:SetText("Whitelist")
        modeToggleButton.text:SetTextColor(0.45, 1, 0.45)
    end
end

modeToggleButton:SetScript("OnClick", function()
    if listMode == "blacklist" then listMode = "whitelist" else listMode = "blacklist" end
    UpdateModeButton()
    LoadList()
end)
UpdateModeButton()

local function ClearEntries()
    for _, entry in ipairs(frame.entries) do entry:Hide() end
    frame.entries = {}
end

local autoDeleteEnabled = true

local function CreateEntry(name, reason)
    local entry = CreateFrame("Frame", nil, content)
    entry:SetSize(350, 35)
    entry:SetBackdrop({
        bgFile = EDIT_BG,
        edgeFile = PANEL_BORDER,
        tile = false, tileSize = 0, edgeSize = 6,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    entry:SetBackdropColor(0.06, 0.07, 0.08, 0.92)
    entry:SetBackdropBorderColor(0.03, 0.03, 0.03)

    entry:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.6, 0.6, 0.6)
    end)
    entry:SetScript("OnLeave", function(self)
        if listMode == "blacklist" then
            self:SetBackdropBorderColor(0.35, 0.05, 0.05)
        else
            self:SetBackdropBorderColor(0.05, 0.35, 0.05)
        end
    end)

    entry.name = entry:CreateFontString(nil, "OVERLAY")
    entry.name:SetPoint("LEFT", 10, 0)
    entry.name:SetFont(FONT, BODY_FONT_SIZE)
    entry.name:SetText(name)
    entry.name:SetTextColor(unpack(LIGHT_TEXT))

    entry.reason = entry:CreateFontString(nil, "OVERLAY")
    entry.reason:SetPoint("LEFT", entry.name, "RIGHT", 10, 0)
    entry.reason:SetFont(FONT, BODY_FONT_SIZE)
    entry.reason:SetText(reason)
    entry.reason:SetTextColor(unpack(DIM_TEXT))
    if listMode == "blacklist" then entry.reason:SetTextColor(1, 0.2, 0.2) else entry.reason:SetTextColor(0.2, 1, 0.2) end

    entry.edit = CreateButton(entry, 50, 20, "Edit")
    entry.edit:SetPoint("RIGHT", entry, "RIGHT", -75, 0)

    entry.edit:SetScript("OnClick", function()
        StaticPopupDialogs["NUGGETLIST_EDIT_REASON"] = {
            text = "Edit Reason for " .. name,
            button1 = "OK",
            button2 = "Cancel",
            hasEditBox = true,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            OnShow = function(self)
                self.editBox:SetText(reason)
                self.editBox:HighlightText()
            end,
            OnAccept = function(self)
                local newReason = self.editBox:GetText()
                if newReason and newReason ~= "" then
                    NuggetListDB[listMode][name] = newReason
                    LoadList()
                end
            end,
        }
        StaticPopup_Show("NUGGETLIST_EDIT_REASON")
    end)

    entry.remove = CreateButton(entry, 60, 20, "Remove")
    entry.remove:SetPoint("RIGHT", entry, "RIGHT", -10, 0)
    entry.remove:SetScript("OnClick", function()
        StaticPopupDialogs["NUGGETLIST_CONFIRM_REMOVE"] = {
            text = "Remove " .. name .. " from " .. listMode .. "?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                NuggetListDB[listMode][name] = nil
                LoadList()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("NUGGETLIST_CONFIRM_REMOVE")
    end)

    table.insert(frame.entries, entry)
end

function LoadList(searchTerm)
    ClearEntries()
    if not NuggetListDB then NuggetListDB = { blacklist = {}, whitelist = {} } end
    local list = NuggetListDB[listMode] or {}
    local index = 0
    for name, reason in pairs(list) do
        if not searchTerm or name:lower():find(searchTerm:lower()) then
            CreateEntry(name, reason)
            local entry = frame.entries[#frame.entries]
            entry:SetPoint("TOPLEFT", 0, -index * 40 - 10)
            entry:Show()
            index = index + 1
        end
    end
    content:SetHeight(math.max(1, index * 40 - 10))
end

local function ShowTextWindow(title, initialText, onAccept)
    if activeTextWindow and activeTextWindow:IsShown() then return end
    local window = CreateFrame("Frame", nil, UIParent)
    activeTextWindow = window
    window:SetSize(400, 300)
    window:SetPoint("CENTER")
    ApplyPanelSkin(window)

    local titleText = window:CreateFontString(nil, "OVERLAY")
    titleText:SetPoint("TOP", 0, -10)
    titleText:SetFont(FONT, TITLE_FONT_SIZE - 1)
    titleText:SetText(title)

    local sf = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -30)
    sf:SetPoint("BOTTOMRIGHT", -28, 40)

    local editBox = CreateFrame("EditBox", nil, sf)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(sf:GetWidth())
    editBox:SetAutoFocus(true)
    editBox:SetText(initialText or "")
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function() window:Hide() activeTextWindow = nil end)

    sf:SetScrollChild(editBox)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
    end)

    local okButton = CreateButton(window, 80, 26, "OK")
    okButton:SetPoint("BOTTOM", 0, 10)
    okButton:SetScript("OnClick", function()
        if onAccept then onAccept(editBox:GetText()) end
        window:Hide()
        activeTextWindow = nil
    end)
end

local function ExportList()
    if not NuggetListDB or not NuggetListDB[listMode] then return end
    local data = {}
    for name, reason in pairs(NuggetListDB[listMode]) do table.insert(data, name .. "=" .. reason) end
    ShowTextWindow("Export " .. listMode:sub(1,1):upper() .. listMode:sub(2), table.concat(data, ";"))
end

local function ImportList()
    ShowTextWindow("Import " .. listMode:sub(1,1):upper() .. listMode:sub(2), "", function(text)
        if not NuggetListDB[listMode] then NuggetListDB[listMode] = {} end
        for pair in string.gmatch(text or "", "([^;]+)") do
            local name, reason = string.match(pair, "^(.-)=(.*)$")
            if name and reason and name ~= "" then NuggetListDB[listMode][name] = reason end
        end
        LoadList()
    end)
end

local addButton = CreateButton(frame, 80, 26, "Add")
addButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", (frame:GetWidth() - 260) / 2, 14)
local importButton = CreateButton(frame, 80, 26, "Import")
importButton:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
local exportButton = CreateButton(frame, 80, 26, "Export")
exportButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
addButton:SetScript("OnClick", function()
    StaticPopupDialogs["NUGGETLIST_NAME"] = {
        text = "Name:",
        button1 = "OK",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            if (name or "") == "" then return end
            StaticPopupDialogs["NUGGETLIST_REASON"] = {
                text = "Reason:",
                button1 = "OK",
                button2 = "Cancel",
                hasEditBox = true,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                OnAccept = function(innerSelf)
                    local reason = innerSelf.editBox:GetText()
                    if (reason or "") == "" then reason = "No reason" end
                    if not NuggetListDB[listMode] then NuggetListDB[listMode] = {} end
                    NuggetListDB[listMode][name] = reason
                    LoadList()
                end,
            }
            StaticPopup_Show("NUGGETLIST_REASON")
        end,
    }
    StaticPopup_Show("NUGGETLIST_NAME")

    local function PasteNameInAddPopup(nm)
        if not nm or nm == "" then return end
        if StaticPopup_Visible("NUGGETLIST_NAME") then
            local dialog = _G["StaticPopup1"]
            if dialog and dialog.editBox then
                dialog.editBox:SetText(nm)
                dialog.editBox:SetFocus()
                dialog.editBox:HighlightText()
            end
        end
    end

    hooksecurefunc("SetItemRef", function(link)
        local prefix, playerName = link:match("^(player):(.+)$")
        if prefix == "player" then
            local cleanName = playerName:match("^[^:-]+")
            PasteNameInAddPopup(cleanName)
        end
    end)

    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G["ChatFrame"..i]
        f:HookScript("OnHyperlinkClick", function(_, link)
            local prefix, playerName = link:match("^(player):(.+)$")
            if prefix == "player" then
                local cleanName = playerName:match("^[^:-]+")
                PasteNameInAddPopup(cleanName)
            end
        end)
    end
end)

importButton:SetScript("OnClick", ImportList)
exportButton:SetScript("OnClick", ExportList)

local closeButton = CreateFrame("Button", nil, frame)
closeButton:SetSize(22, 22)
closeButton:SetPoint("TOPRIGHT", -8, -8)
local cbTex = closeButton:CreateTexture(nil, "BACKGROUND")
cbTex:SetTexture(BUTTON_NORMAL)
cbTex:SetAllPoints(closeButton)
local cbX = closeButton:CreateFontString(nil, "OVERLAY")
cbX:SetFont(FONT, 12)
cbX:SetPoint("CENTER")
cbX:SetText("×")
cbX:SetTextColor(1, 0.6, 0.6)
closeButton:SetScript("OnClick", function() frame:Hide() end)

local searchBox = CreateEditBox(frame, 56, 22, "Search...")
searchBox:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)
searchBox:SetTextColor(unpack(DIM_TEXT))
searchBox:SetTextInsets(3, 0, 0, 0)
searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "Search..." then self:SetText("") self:SetTextColor(unpack(LIGHT_TEXT)) end
end)
searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self:SetText("Search...") self:SetTextColor(unpack(DIM_TEXT)) end
end)
searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text == "" or text == "Search..." then LoadList() else LoadList(text) end
end)

frame:SetScript("OnShow", function() searchBox:Show() UpdateModeButton() end)
frame:HookScript("OnHide", function() searchBox:Hide() end)
searchBox:Hide()

SLASH_NUGGETLIST1 = "/nuggetlist"
SLASH_NUGGETLIST2 = "/nl"
SlashCmdList["NUGGETLIST"] = function() if frame:IsShown() then frame:Hide() else frame:Show() end end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "NuggetList" then
        LoadList()

        hooksecurefunc("StaticPopup_Show", function(which)
            if which == "DELETE_GOOD_ITEM" and autoDeleteEnabled then
                local f = CreateFrame("Frame")
                local elapsed = 0
                f:SetScript("OnUpdate", function(self, e)
                    elapsed = elapsed + e
                    if elapsed > 0.1 then
                        for i = 1, STATICPOPUP_NUMDIALOGS do
                            local frame = _G["StaticPopup"..i]
                            if frame and frame:IsShown() and frame.which == "DELETE_GOOD_ITEM" and frame.editBox then
                                frame.editBox:SetText("DELETE")
                                frame.editBox:ClearFocus()
                                break
                            end
                        end
                        self:SetScript("OnUpdate", nil)
                    end
                end)
            end
        end)

        local function AutoSellGrays()
            for bag = 0, 4 do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemLink = GetContainerItemLink(bag, slot)
                    if itemLink then
                        local _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemLink)
                        if itemRarity == 0 and itemSellPrice and itemSellPrice > 0 then
                            UseContainerItem(bag, slot)
                        end
                    end
                end
            end
        end
        local autoSellFrame = CreateFrame("Frame")
        autoSellFrame:RegisterEvent("MERCHANT_SHOW")
        autoSellFrame:SetScript("OnEvent", AutoSellGrays)

        local nuggetIcon = "|TInterface\\AddOns\\NuggetList\\media\\nuggeticon_cleaned.tga:16:16|t "
        local whitelistIcon = "|TInterface\\AddOns\\NuggetList\\media\\nuggeticon2.tga:16:16|t "
        local function IsBlacklisted(name) return NuggetListDB and NuggetListDB.blacklist and NuggetListDB.blacklist[name] ~= nil end
        local function IsWhitelisted(name) return NuggetListDB and NuggetListDB.whitelist and NuggetListDB.whitelist[name] ~= nil end
        local function AddNuggetIconToChat(self, event, msg, author, ...)
            local cleanName = author and author:match("^[^-]+") or author
            if IsBlacklisted(cleanName) then msg = nuggetIcon .. msg
            elseif IsWhitelisted(cleanName) then msg = whitelistIcon .. msg end
            return false, msg, author, ...
        end

        local chatEvents = {
            "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_GUILD","CHAT_MSG_OFFICER",
            "CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_WHISPER","CHAT_MSG_CHANNEL",
        }
        for _, ev in ipairs(chatEvents) do ChatFrame_AddMessageEventFilter(ev, AddNuggetIconToChat) end
    end
end)
