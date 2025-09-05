local frame = CreateFrame("Frame", "NuggetListFrame", UIParent)
frame:SetSize(400, 450)
frame:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = false, tileSize = 0, edgeSize = 12,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.title:SetPoint("TOP", -16, -15)
frame.title:SetText("NuggetList v0.1")
frame.author = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.author:SetPoint("TOP", frame.title, "BOTTOM", 0, -2)
frame.author:SetText("|cffa335eeby Dopalone|r")

local scrollFrame = CreateFrame("ScrollFrame", "NuggetListScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -36, 50)

local content = CreateFrame("Frame", "NuggetListContent", scrollFrame)
content:SetWidth(370)
content:SetHeight(1)
scrollFrame:SetScrollChild(content)
frame.content = content
frame.entries = {}
local activeTextWindow = nil

local modeToggleButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
modeToggleButton:SetSize(100, 25)
modeToggleButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
modeToggleButton:SetNormalFontObject("GameFontNormal")

local listMode = "whitelist"

local function UpdateModeButton()
    if listMode == "blacklist" then
        modeToggleButton:SetText("Blacklist")
        modeToggleButton:GetFontString():SetTextColor(1, 0, 0)
    elseif listMode == "whitelist" then
        modeToggleButton:SetText("Whitelist")
        modeToggleButton:GetFontString():SetTextColor(0, 1, 0)
    end
end

modeToggleButton:SetScript("OnClick", function()
    if listMode == "blacklist" then
        listMode = "whitelist"
    elseif listMode == "whitelist" then
        listMode = "blacklist"
    end
    UpdateModeButton()
    LoadList()
end)

UpdateModeButton()

local function ClearEntries()
    for _, entry in ipairs(frame.entries) do
        entry:Hide()
    end
    frame.entries = {}
end

local autoDeleteEnabled = true

local function CreateEntry(name, reason)
    local entry = CreateFrame("Frame", nil, content)
    entry:SetSize(350, 35)

    entry:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        tile = false, tileSize = 0, edgeSize = 12,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    entry:SetBackdropColor(0, 0, 0, 0.6)
    entry:SetBackdropBorderColor(0.3, 0.3, 0.3)
	
	entry:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(1, 1, 1)
end)

entry:SetScript("OnLeave", function(self)
    if listMode == "blacklist" then
        self:SetBackdropBorderColor(0.3, 0, 0)
    elseif listMode == "whitelist" then
        self:SetBackdropBorderColor(0, 0.3, 0)
    end
end)

    entry.name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    entry.name:SetPoint("LEFT", 10, 0)
    entry.name:SetText(name)

    entry.reason = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    entry.reason:SetPoint("LEFT", entry.name, "RIGHT", 10, 0)
    entry.reason:SetText(reason)
   if listMode == "blacklist" then
    entry.reason:SetTextColor(1, 0, 0)
   elseif listMode == "whitelist" then
    entry.reason:SetTextColor(0, 1, 0)
   
end

    entry.edit = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
    entry.edit:SetSize(50, 20)
    entry.edit:SetText("Edit")
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

    entry.remove = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
    entry.remove:SetSize(60, 20)
    entry.remove:SetText("Remove")
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
    content:SetHeight(index * 40 - 10)
end

local function ShowTextWindow(title, initialText, onAccept)
    if activeTextWindow and activeTextWindow:IsShown() then return end

    local window = CreateFrame("Frame", nil, UIParent)
    activeTextWindow = window
    window:SetSize(400, 300)
    window:SetPoint("CENTER")
    window:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, tileSize = 0, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    window:SetBackdropColor(0,0,0,1)

    local titleText = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titleText:SetPoint("TOP", 0, -10)
    titleText:SetText(title)

    local scrollFrame = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -10, 40)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(true)
    editBox:SetText(initialText or "")
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function() window:Hide() activeTextWindow = nil end)

    scrollFrame:SetScrollChild(editBox)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
    end)

    local okButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    okButton:SetSize(80, 25)
    okButton:SetPoint("BOTTOM", 0, 10)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function()
        if onAccept then onAccept(editBox:GetText()) end
        window:Hide()
        activeTextWindow = nil
    end)
end

local function ExportList()
    if not NuggetListDB or not NuggetListDB[listMode] then return end
    local data = {}
    for name, reason in pairs(NuggetListDB[listMode]) do
        table.insert(data, name .. "=" .. reason)
    end
    ShowTextWindow("Export " .. listMode:sub(1,1):upper() .. listMode:sub(2), table.concat(data, ";"))
end

local function ImportList()
    ShowTextWindow("Import " .. listMode:sub(1,1):upper() .. listMode:sub(2), "", function(text)
        if not NuggetListDB[listMode] then NuggetListDB[listMode] = {} end
        for pair in string.gmatch(text, "([^;]+)") do
            local name, reason = string.match(pair, "^(.-)=(.*)$")
            if name and reason and name ~= "" then
                NuggetListDB[listMode][name] = reason
            end
        end
        LoadList()
    end)
end

local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
addButton:SetSize(80, 25)
addButton:SetText("Add")

local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
importButton:SetSize(80, 25)
importButton:SetText("Import")
importButton:SetScript("OnClick", function()
    ShowTextWindow("Import " .. listMode, "", function(text)
        if not text or text == "" then return end
        if not NuggetListDB[listMode] then NuggetListDB[listMode] = {} end
        for pair in string.gmatch(text, "([^;]+)") do
            local name, reason = string.match(pair, "^(.-)=(.*)$")
            if name and reason then
                NuggetListDB[listMode][name] = reason
            end
        end
        LoadList()
    end)
end)

local exportButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
exportButton:SetSize(80, 25)
exportButton:SetText("Export")
exportButton:SetScript("OnClick", function()
    if not NuggetListDB or not NuggetListDB[listMode] then return end
    local data = {}
    for name, reason in pairs(NuggetListDB[listMode]) do
        table.insert(data, name .. "=" .. reason)
    end
    ShowTextWindow("Export " .. listMode, table.concat(data, ";"), function(_) end)
end)

local totalWidth = 80 + 80 + 80 + (10 * 2)
local startX = (frame:GetWidth() - totalWidth) / 2

addButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", startX, 14)
importButton:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
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
            if name == "" then return end
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
                    if reason == "" then reason = "No reason" end
                    if not NuggetListDB[listMode] then NuggetListDB[listMode] = {} end
					NuggetListDB[listMode][name] = reason

                    LoadList()
                end,
            }
            StaticPopup_Show("NUGGETLIST_REASON")
        end,
    }
    StaticPopup_Show("NUGGETLIST_NAME")
local function PasteNameInAddPopup(name)
    if not name or name == "" then return end
    if StaticPopup_Visible("NUGGETLIST_NAME") then
        local dialog = _G["StaticPopup1"] -- First StaticPopup
        if dialog and dialog.editBox then
            dialog.editBox:SetText(name)
            dialog.editBox:SetFocus()
            dialog.editBox:HighlightText()
        end
    end
end

hooksecurefunc("SetItemRef", function(link, text, button)
    local prefix, playerName = link:match("^(player):(.+)$")
    if prefix == "player" then
        local cleanName = playerName:match("^[^:-]+")
        PasteNameInAddPopup(cleanName)
    end
end)

for i = 1, NUM_CHAT_WINDOWS do
    local f = _G["ChatFrame"..i]
    f:HookScript("OnHyperlinkClick", function(_, link, text, button)
        local prefix, playerName = link:match("^(player):(.+)$")
        if prefix == "player" then
            local cleanName = playerName:match("^[^:-]+")
            PasteNameInAddPopup(cleanName)
        end
    end)
end

end)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -6, -6)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

local searchBox = CreateFrame("EditBox", "NuggetListSearchBox", UIParent, "InputBoxTemplate")
searchBox:SetHeight(28)
searchBox:ClearAllPoints()
searchBox:SetPoint("RIGHT", closeButton, "LEFT", 1, -7)
searchBox:SetPoint("TOP", closeButton, "TOP", 1, -7)
searchBox:SetParent(frame)
searchBox:SetFrameLevel(closeButton:GetFrameLevel())
searchBox:Show()
searchBox:SetWidth(100)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnTextChanged", function(self)
    LoadList(self:GetText())
end)

searchBox:SetText("Search...")
searchBox:SetTextColor(0.5, 0.5, 0.5)

searchBox:SetScript("OnEditFocusGained", function(self)
    if self:GetText() == "Search..." then
        self:SetText("")
        self:SetTextColor(1, 1, 1)
    end
end)

searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then
        self:SetText("Search...")
        self:SetTextColor(0.5, 0.5, 0.5)
    end
end)

searchBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text == "" or text == "Search..." then
        LoadList()
    else
        LoadList(text)
    end
end)

frame:SetScript("OnShow", function()
    searchBox:Show()
	UpdateModeButton()
end)
frame:HookScript("OnHide", function() searchBox:Hide() end)
searchBox:Hide()

SLASH_NUGGETLIST1 = "/nuggetlist"
SLASH_NUGGETLIST2 = "/nl"
SlashCmdList["NUGGETLIST"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

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
                if itemRarity == 0 and itemSellPrice > 0 then
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
end

local autoSellFrame = CreateFrame("Frame")
autoSellFrame:RegisterEvent("MERCHANT_SHOW")
autoSellFrame:SetScript("OnEvent", AutoSellGrays)

        local nuggetIcon = "|TInterface\\AddOns\\NuggetList\\nuggeticon_cleaned.tga:16:16|t "
		local whitelistIcon = "|TInterface\\AddOns\\NuggetList\\nuggeticon2.tga:16:16|t "


local function IsBlacklisted(name)
    return NuggetListDB and NuggetListDB.blacklist and NuggetListDB.blacklist[name] ~= nil
end

local function IsWhitelisted(name)
    return NuggetListDB and NuggetListDB.whitelist and NuggetListDB.whitelist[name] ~= nil
end

local function AddNuggetIconToChat(self, event, msg, author, ...)
    local cleanName = author and author:match("^[^-]+") or author

    if IsBlacklisted(cleanName) then
        msg = nuggetIcon .. msg
    elseif IsWhitelisted(cleanName) then
        msg = whitelistIcon .. msg
    end

    return false, msg, author, ...
end



        local chatEvents = {
            "CHAT_MSG_SAY",
            "CHAT_MSG_YELL",
            "CHAT_MSG_GUILD",
            "CHAT_MSG_OFFICER",
            "CHAT_MSG_PARTY",
            "CHAT_MSG_PARTY_LEADER",
            "CHAT_MSG_RAID",
            "CHAT_MSG_RAID_LEADER",
            "CHAT_MSG_WHISPER",
            "CHAT_MSG_CHANNEL",
        }

        for _, event in ipairs(chatEvents) do
            ChatFrame_AddMessageEventFilter(event, AddNuggetIconToChat)
        end
    end
end)

