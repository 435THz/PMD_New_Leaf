---@meta

---@class LuaClass<T> A root class that only exists to avoid missing :new issues
local LuaClass
---Calls the initialization method
---@generic T
---@param this T #the object in question
---@param ... any parameters for the initialize function
---@return T
function LuaClass.new(this, ...) return this end

---@class InputManager
---@field Direction userdata
---@field PrevDirection userdata
---@field InputTime integer
local InputManager
---@param button any
function InputManager:JustPressed(button) end




---@class ScriptableMultiPageMenu
---@field Bounds Rect
---@field ChoiceChangedFunction fun()
---@field MultiSelectChangedFunction fun()
---@field UpdateFunction fun(input)
---@field SummaryMenus List<Menu>
---@field CurrentChoice integer
---@field CurrentChoiceTotal integer
---@field CurrentPage integer
local ScriptableMultiPageMenu
---Returns the choice at the given total index
---@param index integer the index to fetch
---@return Selectable
function ScriptableMultiPageMenu:GetTotalChoiceAtIndex(index) end
---Changes the current page to the requested one
---@param page integer the page to set
function ScriptableMultiPageMenu:SetCurrentPage(page) end
---@return List<Selectable>
function ScriptableMultiPageMenu:ExportChoices() end
---@param list List<Selectable>
function ScriptableMultiPageMenu:ImportChoices(list) end



---@class ItemSummary : LuaClass
---@field Bounds Rect
local ItemSummary
---Updates the displayed data using the giben InvItem
---@param item InvItem
function ItemSummary:SetItem(item) end



---@class MenuTextChoice : Selectable
---@field Text MenuText
---@field ChoiceAction fun()
local MenuTextChoice
function MenuTextChoice:OnConfirm() end

---@class MenuElementsChoice : Selectable
---@field Elements List<userdata>
---@field ChoiceAction fun()
local MenuElementsChoice

---@class MenuText
local MenuText
---@param text string
function MenuText:SetText(text) end
---@return integer
function MenuText:GetTextLength() end



---@class List<T> : { [integer]: T, Count: integer }
local List
---Adds the given element to the end of the list
---@generic T : any
---@param this List<T>
---@param elem T
function List.Add(this, elem) end
---Adds the given element to the list in the specified position, shifting all elements forwards by 1 from pos onward to make space for it.
---@generic T : any
---@param this List<T>
---@param integer integer
---@param elem T
function List.Insert(this, integer, elem) end
---Removes the element in the specified position, shifting all following elements backwards by 1 to fill the gap.
---@generic T : any
---@param this List<T>
---@param integer integer
function List.Remove(this, integer) end



---@class Selectable
---@field Enabled boolean
---@field Selected boolean
local Selectable
---Silently changes the selection state
---@param state boolean the state to set
function Selectable:SilentSelect(state) end
function Selectable:OnConfirm() end



---@alias InvSlot {Slot:integer,IsEquipped:boolean,IsValid:(fun():boolean)}
---@alias InvItem {ID:string,Cursed:boolean,HiddenValue:string,Amount:integer,Price:integer,GetSellValue:(fun(this:InvItem):integer),GetDisplayName:(fun(this:InvItem):string)}
---@alias ItemData {Desc:LocalText,Rarity:integer,MaxStack:integer,Price:integer,UsageType:userdata}
---@alias LocalText {ToLocal:(fun():string)}
---@alias MonsterID {Species:string,Form:integer,Skin:string,Gender:any}
---@alias SlotSkill {SkillNum:string,Charges:integer,CanForget:boolean}
---@alias Character {Name:string,BaseForm:MonsterID,BaseIntrinsics:List<string>,FormIntrinsicSlot:integer,BaseSkills:List<SlotSkill>,Level:integer,MaxHP:integer,BaseAtk:integer,BaseDef:integer,BaseMAtk:integer,BaseMDef:integer,BaseSpeed:integer,MaxHPBonus:integer,AtkBonus:integer,DefBonus:integer,MAtkBonus:integer,MDefBonus:integer,SpeedBonus:integer,LuaData:table,SetBaseIntrinsic:function,GetDisplayName:(fun(this:Character,trueName:boolean):string),HasBaseSkill:(fun(this:Character,skill_id:string):boolean)}
---@alias Menu {Bounds:Rect}
---@alias Rect {X:integer,Y:integer,Width:integer,Height:integer,Left:integer,Right:integer,Top:integer,Bottom:integer}
---@alias Loc {X:integer,Y:integer}

---@alias ItemEntry {Item:string,Amount:integer}
---@alias MonsterIDLua {Species:string,Form:integer,Skin:string,Gender:integer}
---@alias InvItemLua {ID:string,Cursed:boolean,HiddenValue:string,Amount:integer,Price:integer}
---@alias StartData {ability:string,boosts:{MHP:integer,ATK:integer,DEF:integer,SAT:integer,SDF:integer,SPE:integer},form_ability_slot:integer,form_data:MonsterIDLua,moves:string[]}
---@alias UpgradeOption {string:string,price:ItemEntry[][],requirements:string[],description:string,sub_description:string,sub_choices:string[],max:integer,per_sub_choice:boolean}
---@alias BuildingData {Shopkeepers:ShopkeeperData[], Upgrades:string[][], Graphics:BuildingGraphics}
---@alias ShopkeeperData {species:string, form?:integer}
---@alias BuildingGraphics {Base:string,NPC_Loc:Loc,TopLayer:string,Marker_Loc:Loc,Bounds:BoundingBoxData[],Decorations:DecorationData[]}
---@alias BoundingBoxData {Name:string,Solid:boolean,X:integer,Y:integer,W:integer,H:integer,Display:DisplayData,Trigger?:userdata}
---@alias DecorationData {X:integer,Y:integer,Display:DisplayData}
---@alias DisplayData {Sprite:string,FrameLength:integer,Start:integer,End:integer}
---@alias NonBlockingData {Base:string,TopLayer:string,Decorations:DecorationData[]}
---@alias BlockingData {Base:string,TopLayer:string,Bounds:BoundingBoxData[],Decorations:DecorationData[]}

---@alias GraphicsData BuildingGraphics|BlockingData|NonBlockingData

---@alias PlotData {unlocked:boolean,building:BuildingID,upgrades:table<string,integer>,shopkeeper:ShopkeeperData,shopkeeper_shiny:boolean,data:table,empty:integer}
---@alias UpgradeEntry {type:string,count:integer}
---@alias UpgradeTree table<string,UpgradeBranch>
---@alias UpgradeBranch {has_sub:boolean,sub?:string[]}
---@alias BuildingID "home"|"office"|"market"|"tutor"|"exporter"|"trader"|"appraisal"|"cafe"|""
---@alias PlotIndex "home"|"office"|number