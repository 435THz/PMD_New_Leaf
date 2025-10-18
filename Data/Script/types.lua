---@meta

---@class Class<T> A root class that only exists to avoid missing :new issues
local Class
---Calls the initialization method
---@generic T
---@param this T #the object in question
---@param ... any parameters for the initialize function
---@return T
function Class.new(this, ...) return this end

---@class List<T>: { [integer]: T, Count: integer }
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