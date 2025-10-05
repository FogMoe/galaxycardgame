Auxiliary = {}
aux = Auxiliary
NULL_VALUE=-10

--the lua version of the bit32 lib, which is deprecated in lua 5.3
bit={}
function bit.band(a,b)
	return a&b
end
function bit.bor(a,b)
	return a|b
end
function bit.bxor(a,b)
	return a~b
end
function bit.lshift(a,b)
	return a<<b
end
function bit.rshift(a,b)
	return a>>b
end
function bit.bnot(a)
	return ~a
end
local function fieldargs(f,width)
	local w=width or 1
	assert(f>=0,"field cannot be negative")
	assert(w>0,"width must be positive")
	assert(f+w<=32,"trying to access non-existent bits")
	return f,~(-1<<w)
end
function bit.extract(r,field,width)
	width=width or 1
	local f,m=fieldargs(field,width)
	return (r>>f)&m
end
function bit.replace(r,v,field,width)
	width=width or 1
	local f,m=fieldargs(field,width)
	return (r&~(m<<f))|((v&m)<< f)
end

---Subgroup check function
---@param sg Group
---@param c Card|nil
---@param g Group
---@return boolean
Auxiliary.GCheckAdditional=function(sg,c,g) return true end

--the table of xyz number
Auxiliary.xyz_number={}
function Auxiliary.GetXyzNumber(v)
	local id
	if Auxiliary.GetValueType(v)=="Card" then id=v:GetCode() end
	if Auxiliary.GetValueType(v)=="number" then id=v end
	return Auxiliary.xyz_number[id]
end

--iterator for getting playerid of current turn player and the other player
function Auxiliary.TurnPlayers()
	local i=0
	return  function()
				i=i+1
				if i==1 then return Duel.GetTurnPlayer() end
				if i==2 then return 1-Duel.GetTurnPlayer() end
			end
end

Auxiliary.idx_table=table.pack(1,2,3,4,5,6,7,8)

function Auxiliary.Stringid(code,id)
	return code*16+id
end
function Auxiliary.Next(g)
	local first=true
	return  function()
				if first then first=false return g:GetFirst()
				else return g:GetNext() end
			end
end
function Auxiliary.NULL()
end
function Auxiliary.TRUE()
	return true
end
function Auxiliary.FALSE()
	return false
end
function Auxiliary.AND(...)
	local function_list={...}
	return  function(...)
				local res=false
				for i,f in ipairs(function_list) do
					res=f(...)
					if not res then return res end
				end
				return res
			end
end
function Auxiliary.OR(...)
	local function_list={...}
	return  function(...)
				local res=false
				for i,f in ipairs(function_list) do
					res=f(...)
					if res then return res end
				end
				return res
			end
end
function Auxiliary.NOT(f)
	return  function(...)
				return not f(...)
			end
end
function Auxiliary.BeginPuzzle(effect)
	local e1=Effect.GlobalEffect()
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TURN_END)
	e1:SetCountLimit(1)
	e1:SetOperation(Auxiliary.PuzzleOp)
	Duel.RegisterEffect(e1,0)
	local e2=Effect.GlobalEffect()
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_SKIP_DP)
	e2:SetTargetRange(1,0)
	Duel.RegisterEffect(e2,0)
	local e3=Effect.GlobalEffect()
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_SKIP_SP)
	e3:SetTargetRange(1,0)
	Duel.RegisterEffect(e3,0)
end
function Auxiliary.PuzzleOp(e,tp)
	Duel.SetLP(0,0)
end
---Duel.SelectOption with option condition
---Return value starts from 1, different from Duel.SelectOption
---@param tp integer
---@param ... table {condition, option[, value]}
---@return integer
function Auxiliary.SelectFromOptions(tp,...)
	local options={...}
	local ops={}
	local opvals={}
	for i=1,#options do
		if options[i][1] then
			table.insert(ops,options[i][2])
			table.insert(opvals,options[i][3] or i)
		end
	end
	if #ops==0 then return nil end
	local select=Duel.SelectOption(tp,table.unpack(ops))
	return opvals[select+1]
end
--register effect of return to hand for Spirit monsters
function Auxiliary.EnableSpiritReturn(c,event1,...)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(event1)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetOperation(Auxiliary.SpiritReturnReg)
	c:RegisterEffect(e1)
	for i,event in ipairs{...} do
		local e2=e1:Clone()
		e2:SetCode(event)
		c:RegisterEffect(e2)
	end
end
function Auxiliary.SpiritReturnReg(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetDescription(1104)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetReset(RESET_EVENT+0xd7e0000+RESET_PHASE+PHASE_END)
	e1:SetCondition(Auxiliary.SpiritReturnConditionForced)
	e1:SetTarget(Auxiliary.SpiritReturnTargetForced)
	e1:SetOperation(Auxiliary.SpiritReturnOperation)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCondition(Auxiliary.SpiritReturnConditionOptional)
	e2:SetTarget(Auxiliary.SpiritReturnTargetOptional)
	c:RegisterEffect(e2)
end
function Auxiliary.SpiritReturnConditionForced(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not c:IsHasEffect(EFFECT_SPIRIT_DONOT_RETURN) and not c:IsHasEffect(EFFECT_SPIRIT_MAYNOT_RETURN)
end
function Auxiliary.SpiritReturnTargetForced(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function Auxiliary.SpiritReturnConditionOptional(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not c:IsHasEffect(EFFECT_SPIRIT_DONOT_RETURN) and c:IsHasEffect(EFFECT_SPIRIT_MAYNOT_RETURN)
end
function Auxiliary.SpiritReturnTargetOptional(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function Auxiliary.SpiritReturnOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end
function Auxiliary.EnableNeosReturn(c,operation,set_category)
	--return
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(1193)
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(Auxiliary.NeosReturnConditionForced)
	e1:SetTarget(Auxiliary.NeosReturnTargetForced(set_category))
	e1:SetOperation(operation)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCondition(Auxiliary.NeosReturnConditionOptional)
	e2:SetTarget(Auxiliary.NeosReturnTargetOptional(set_category))
	c:RegisterEffect(e2)
	return e1,e2
end
function Auxiliary.NeosReturnConditionForced(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsHasEffect(42015635)
end
function Auxiliary.NeosReturnTargetForced(set_category)
	return  function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then return true end
				Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
				if set_category then set_category(e,tp,eg,ep,ev,re,r,rp) end
			end
end
function Auxiliary.NeosReturnConditionOptional(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsHasEffect(42015635)
end
function Auxiliary.NeosReturnTargetOptional(set_category)
	return  function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then return e:GetHandler():IsAbleToExtra() end
				Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
				if set_category then set_category(e,tp,eg,ep,ev,re,r,rp) end
			end
end
---add "Toss a coin and get the following effects" effect to Arcana Force monsters
---@param c Card
---@param event1 integer
---@param ... integer
function Auxiliary.EnableArcanaCoin(c,event1,...)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(1623)
	e1:SetCategory(CATEGORY_COIN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(event1)
	e1:SetTarget(Auxiliary.ArcanaCoinTarget)
	e1:SetOperation(Auxiliary.ArcanaCoinOperation)
	c:RegisterEffect(e1)
	for _,event in ipairs{...} do
		local e2=e1:Clone()
		e2:SetCode(event)
		c:RegisterEffect(e2)
	end
end
function Auxiliary.ArcanaCoinTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
end
function Auxiliary.ArcanaCoinOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local res=0
	local toss=false
	if Duel.IsPlayerAffectedByEffect(tp,73206827) then
		res=1-Duel.SelectOption(tp,60,61)
	else
		res=Duel.TossCoin(tp,1)
		toss=true
	end
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	if toss then
		c:RegisterFlagEffect(FLAG_ID_REVERSAL_OF_FATE,RESET_EVENT+RESETS_STANDARD,0,1)
	end
	c:RegisterFlagEffect(FLAG_ID_ARCANA_COIN,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,res,63-res)
end
---condition of Arcana Force monster effect from coin toss
---@param e Effect
---@return boolean
function Auxiliary.ArcanaCondition(e)
	return e:GetHandler():GetFlagEffect(FLAG_ID_ARCANA_COIN)>0
end
function Auxiliary.IsUnionState(effect)
	local c=effect:GetHandler()
	return c:IsHasEffect(EFFECT_UNION_STATUS) and c:GetEquipTarget()
end
--set EFFECT_EQUIP_LIMIT after equipping
function Auxiliary.SetUnionState(c)
	local eset={c:IsHasEffect(EFFECT_UNION_LIMIT)}
	if #eset==0 then return end
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(eset[1]:GetValue())
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UNION_STATUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
	if c.old_union then
		local e2=e1:Clone()
		e2:SetCode(EFFECT_OLDUNION_STATUS)
		c:RegisterEffect(e2)
	end
end
--uc: the union monster to be equipped, tc: the target monster
function Auxiliary.CheckUnionEquip(uc,tc,exclude_modern_count)
	local modern_count,old_count=tc:GetUnionCount()
	if exclude_modern_count then modern_count=modern_count-exclude_modern_count end
	if uc.old_union then return modern_count==0
	else return old_count==0 end
end
--EFFECT_DESTROY_SUBSTITUTE filter for modern union monsters
function Auxiliary.UnionReplaceFilter(e,re,r,rp)
	return r&(REASON_BATTLE+REASON_EFFECT)~=0
end
---add effect to modern union monsters
---@param c Card
---@param filter function
function Auxiliary.EnableUnionAttribute(c,filter)
	local equip_limit=Auxiliary.UnionEquipLimit(filter)
	--destroy sub
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e1:SetValue(Auxiliary.UnionReplaceFilter)
	c:RegisterEffect(e1)
	--limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UNION_LIMIT)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(equip_limit)
	c:RegisterEffect(e2)
	--equip
	local equip_filter=Auxiliary.UnionEquipFilter(filter)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(1068)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(Auxiliary.UnionEquipTarget(equip_filter))
	e3:SetOperation(Auxiliary.UnionEquipOperation(equip_filter))
	c:RegisterEffect(e3)
	--unequip
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(1152)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTarget(Auxiliary.UnionUnequipTarget)
	e4:SetOperation(Auxiliary.UnionUnequipOperation)
	c:RegisterEffect(e4)
end
function Auxiliary.UnionEquipFilter(filter)
	return  function(c,tp)
				local ct1,ct2=c:GetUnionCount()
				return c:IsFaceup() and ct2==0 and c:IsControler(tp) and filter(c)
			end
end
function Auxiliary.UnionEquipLimit(filter)
	return  function(e,c)
				return (c:IsControler(e:GetHandlerPlayer()) and filter(c)) or e:GetHandler():GetEquipTarget()==c
			end
end
function Auxiliary.UnionEquipTarget(equip_filter)
	return  function(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
				local c=e:GetHandler()
				if chkc then return chkc:IsLocation(LOCATION_MZONE) and equip_filter(chkc,tp) end
				if chk==0 then return c:GetFlagEffect(FLAG_ID_UNION)==0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
					and Duel.IsExistingTarget(equip_filter,tp,LOCATION_MZONE,0,1,c,tp) end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
				local g=Duel.SelectTarget(tp,equip_filter,tp,LOCATION_MZONE,0,1,1,c,tp)
				Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
				c:RegisterFlagEffect(FLAG_ID_UNION,RESET_EVENT+0x7e0000+RESET_PHASE+PHASE_END,0,1)
			end
end
function Auxiliary.UnionEquipOperation(equip_filter)
	return  function(e,tp,eg,ep,ev,re,r,rp)
				local c=e:GetHandler()
				local tc=Duel.GetFirstTarget()
				if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
				if not tc:IsRelateToEffect(e) or not equip_filter(tc,tp) then
					Duel.SendtoGrave(c,REASON_RULE)
					return
				end
				if not Duel.Equip(tp,c,tc,false) then return end
				Auxiliary.SetUnionState(c)
			end
end
function Auxiliary.UnionUnequipTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:GetFlagEffect(FLAG_ID_UNION)==0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:GetEquipTarget() and c:IsCanBeSpecialSummoned(e,0,tp,true,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	c:RegisterFlagEffect(FLAG_ID_UNION,RESET_EVENT+0x7e0000+RESET_PHASE+PHASE_END,0,1)
end
function Auxiliary.UnionUnequipOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.SpecialSummon(c,0,tp,tp,true,false,POS_FACEUP)
end
function Auxiliary.EnableChangeCode(c,code,location,condition)
	Auxiliary.AddCodeList(c,code)
	local loc=c:GetOriginalType()&TYPE_MONSTER~=0 and LOCATION_MZONE or LOCATION_SZONE
	loc=location or loc
	if condition==nil then condition=Auxiliary.TRUE end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(loc)
	e1:SetCondition(condition)
	e1:SetValue(code)
	c:RegisterEffect(e1)
	return e1
end
function Auxiliary.TargetEqualFunction(f,value,...)
	local ext_params={...}
	return  function(effect,target)
				return f(target,table.unpack(ext_params))==value
			end
end
function Auxiliary.TargetBoolFunction(f,...)
	local ext_params={...}
	return  function(effect,target)
				return f(target,table.unpack(ext_params))
			end
end
function Auxiliary.FilterEqualFunction(f,value,...)
	local ext_params={...}
	return  function(target)
				return f(target,table.unpack(ext_params))==value
			end
end
function Auxiliary.FilterBoolFunction(f,...)
	local ext_params={...}
	return  function(target)
				return f(target,table.unpack(ext_params))
			end
end
function Auxiliary.GetValueType(v)
	local t=type(v)
	if t=="userdata" then
		local mt=getmetatable(v)
		if mt==Group then return "Group"
		elseif mt==Effect then return "Effect"
		else return "Card" end
	else return t end
end
--Extra Deck summon count
function Auxiliary.EnableExtraDeckSummonCountLimit()
	if Auxiliary.ExtraDeckSummonCountLimit~=nil then return end
	Auxiliary.ExtraDeckSummonCountLimit={}
	Auxiliary.ExtraDeckSummonCountLimit[0]=1
	Auxiliary.ExtraDeckSummonCountLimit[1]=1
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	ge1:SetCode(EVENT_PHASE_START+PHASE_DRAW)
	ge1:SetOperation(Auxiliary.ExtraDeckSummonCountLimitReset)
	Duel.RegisterEffect(ge1,0)
end
function Auxiliary.ExtraDeckSummonCountLimitReset()
	Auxiliary.ExtraDeckSummonCountLimit[0]=1
	Auxiliary.ExtraDeckSummonCountLimit[1]=1
end
--Fusion Monster is unnecessary to use this
function Auxiliary.AddMaterialCodeList(c,...)
	if c:IsStatus(STATUS_COPYING_EFFECT) then return end
	local mat={}
	for _,code in ipairs{...} do
		mat[code]=true
	end
	if c.material==nil then
		local mt=getmetatable(c)
		mt.material=mat
	end
	for index,_ in pairs(mat) do
		Auxiliary.AddCodeList(c,index)
	end
end
function Auxiliary.IsMaterialListCode(c,code)
	return c.material and c.material[code]
end
function Auxiliary.IsMaterialListSetCard(c,setcode)
	if not c.material_setcode then return false end
	if type(c.material_setcode)=="table" then
		for i,scode in ipairs(c.material_setcode) do
			if setcode&0xfff==scode&0xfff and setcode&scode==setcode then return true end
		end
	else
		return setcode&0xfff==c.material_setcode&0xfff and setcode&c.material_setcode==setcode
	end
	return false
end
function Auxiliary.IsMaterialListType(c,type)
	return c.material_type and type&c.material_type==type
end
function Auxiliary.GetMaterialListCount(c)
	if not c.material_count then return 0,0 end
	return c.material_count[1],c.material_count[2]
end
function Auxiliary.AddCodeList(c,...)
	if c:IsStatus(STATUS_COPYING_EFFECT) then return end
	if c.card_code_list==nil then
		local mt=getmetatable(c)
		mt.card_code_list={}
		for _,code in ipairs{...} do
			mt.card_code_list[code]=true
		end
	else
		for _,code in ipairs{...} do
			c.card_code_list[code]=true
		end
	end
end
function Auxiliary.IsCodeListed(c,code)
	return c.card_code_list and c.card_code_list[code]
end
function Auxiliary.IsCodeOrListed(c,code)
	return c:IsCode(code) or Auxiliary.IsCodeListed(c,code)
end
function Auxiliary.AddSetNameMonsterList(c,...)
	if c:IsStatus(STATUS_COPYING_EFFECT) then return end
	if c.setcode_monster_list==nil then
		local mt=getmetatable(c)
		mt.setcode_monster_list={}
		for i,scode in ipairs{...} do
			mt.setcode_monster_list[i]=scode
		end
	else
		for i,scode in ipairs{...} do
			c.setcode_monster_list[i]=scode
		end
	end
end
function Auxiliary.IsSetNameMonsterListed(c,setcode)
	if not c.setcode_monster_list then return false end
	for i,scode in ipairs(c.setcode_monster_list) do
		if setcode&0xfff==scode&0xfff and setcode&scode==setcode then return true end
	end
	return false
end
function Auxiliary.IsCounterAdded(c,counter)
	if not c.counter_add_list then return false end
	for i,ccounter in ipairs(c.counter_add_list) do
		if counter==ccounter then return true end
	end
	return false
end
function Auxiliary.IsTypeInText(c,type)
	return c.has_text_type and type&c.has_text_type==type
end
function Auxiliary.GetAttributeCount(g)
	if #g==0 then return 0 end
	local att=0
	for tc in Auxiliary.Next(g) do
		att=att|tc:GetAttribute()
	end
	local ct=0
	while att~=0 do
		if att&0x1~=0 then ct=ct+1 end
		att=att>>1
	end
	return ct
end
function Auxiliary.IsInGroup(c,g)
	return g:IsContains(c)
end
--Get the row index (from the viewpoint of controller)
function Auxiliary.GetLocalRow(location,sequence)
	if location==LOCATION_SZONE then
		if 0<=sequence and sequence<=4 then
			return 0
		else
			return NULL_VALUE
		end
	elseif location==LOCATION_MZONE then
		if 0<=sequence and sequence<=4 then
			return 1
		elseif 5<=sequence and sequence<=6 then
			return 2
		else
			return NULL_VALUE
		end
	else
		return NULL_VALUE
	end
end
--Get the global row index (from the viewpoint of 0)
function Auxiliary.GetGlobalRow(p,location,sequence)
	local row=Auxiliary.GetLocalRow(location,sequence)
	if row<0 then
		return NULL_VALUE
	end
	if p==0 then
		return row
	else
		return 4-row
	end
end
--Get the column index (from the viewpoint of controller)
function Auxiliary.GetLocalColumn(location,sequence)
	if location==LOCATION_SZONE then
		if 0<=sequence and sequence<=4 then
			return sequence
		else
			return NULL_VALUE
		end
	elseif location==LOCATION_MZONE then
		if 0<=sequence and sequence<=4 then
			return sequence
		elseif sequence==5 then
			return 1
		elseif sequence==6 then
			return 3
		else
			return NULL_VALUE
		end
	else
		return NULL_VALUE
	end
end
--Get the global column index (from the viewpoint of 0)
function Auxiliary.GetGlobalColumn(p,location,sequence)
	local column=Auxiliary.GetLocalColumn(location,sequence)
	if column<0 then
		return NULL_VALUE
	end
	if p==0 then
		return column
	else
		return 4-column
	end
end
---Get the global row and column index of c
---@param c Card
---@return integer
---@return integer
function Auxiliary.GetFieldIndex(c)
	local cp=c:GetControler()
	local loc=c:GetLocation()
	local seq=c:GetSequence()
	return Auxiliary.GetGlobalRow(cp,loc,seq),Auxiliary.GetGlobalColumn(cp,loc,seq)
end
---Check if c is adjacent to (i,j)
---@param c Card
---@param i integer
---@param j integer
---@return boolean
function Auxiliary.AdjacentFilter(c,i,j)
	local row,column=Auxiliary.GetFieldIndex(c)
	if row<0 or column<0 then
		return false
	end
	return (row==i and math.abs(column-j)==1) or (math.abs(row-i)==1 and column==j)
end
---Get the card group adjacent to (i,j)
---@param tp integer
---@param location1 integer
---@param location2 integer
---@param i integer
---@param j integer
---@return Group
function Auxiliary.GetAdjacentGroup(tp,location1,location2,i,j)
	return Duel.GetMatchingGroup(Auxiliary.AdjacentFilter,tp,location1,location2,nil,i,j)
end
---Get the column index of card c (from the viewpoint of p)
---@param c Card
---@param p? integer default: 0
---@return integer
function Auxiliary.GetColumn(c,p)
	p=p or 0
	local cp=c:GetControler()
	local loc=c:GetLocation()
	local seq=c:GetSequence()
	local column=Auxiliary.GetGlobalColumn(cp,loc,seq)
	if column<0 then
		return NULL_VALUE
	end
	if p==0 then
		return column
	else
		return 4-column
	end
end
--return the column of monster zone seq (from the viewpoint of controller)
function Auxiliary.MZoneSequence(seq)
	return Auxiliary.GetLocalColumn(LOCATION_MZONE,seq)
end
--return the column of spell/trap zone seq (from the viewpoint of controller)
function Auxiliary.SZoneSequence(seq)
	return Auxiliary.GetLocalColumn(LOCATION_SZONE,seq)
end
--generate the value function of EFFECT_CHANGE_BATTLE_DAMAGE on monsters
function Auxiliary.ChangeBattleDamage(player,value)
	return  function(e,damp)
				if player==0 then
					if e:GetOwnerPlayer()==damp then
						return value
					else
						return -1
					end
				elseif player==1 then
					if e:GetOwnerPlayer()==1-damp then
						return value
					else
						return -1
					end
				end
			end
end
--filter for "negate the effects of a face-up monster" (無限泡影/Infinite Impermanence)
function Auxiliary.NegateMonsterFilter(c)
	return c:IsFaceup() and not c:IsDisabled() and (c:IsType(TYPE_EFFECT) or c:GetOriginalType()&TYPE_EFFECT~=0)
end
--filter for "negate the effects of an Effect Monster" (エフェクト・ヴェーラー/Effect Veiler)
function Auxiliary.NegateEffectMonsterFilter(c)
	return c:IsFaceup() and not c:IsDisabled() and c:IsType(TYPE_EFFECT)
end
--filter for "negate the effects of a face-up card"
function Auxiliary.NegateAnyFilter(c)
	if c:IsType(TYPE_TRAPMONSTER) then
		return c:IsFaceup()
	elseif c:IsType(TYPE_SPELL+TYPE_TRAP) then
		return c:IsFaceup() and not c:IsDisabled()
	else
		return Auxiliary.NegateMonsterFilter(c)
	end
end
--alias for compatibility
Auxiliary.disfilter1=Auxiliary.NegateAnyFilter
--condition of EVENT_BATTLE_DESTROYING
function Auxiliary.bdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle()
end
--condition of EVENT_BATTLE_DESTROYING + opponent monster
function Auxiliary.bdocon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle() and c:IsStatus(STATUS_OPPO_BATTLE)
end
--condition of EVENT_BATTLE_DESTROYING + to_grave
function Auxiliary.bdgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
--condition of EVENT_BATTLE_DESTROYING + opponent monster + to_grave
function Auxiliary.bdogcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and c:IsStatus(STATUS_OPPO_BATTLE) and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
--condition of EVENT_DAMAGE_STEP_END + this monster is releate to battle
function Auxiliary.dsercon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle() or c:IsStatus(STATUS_BATTLE_DESTROYED)
end
--condition of EVENT_TO_GRAVE + destroyed by opponent
function Auxiliary.dogcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousControler(tp) and c:IsReason(REASON_DESTROY) and rp==1-tp
end
--condition of EVENT_TO_GRAVE + destroyed by opponent + from field
function Auxiliary.dogfcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and c:IsReason(REASON_DESTROY) and rp==1-tp
end
--condition of "except the turn this card was sent to the Graveyard"
function Auxiliary.exccon(e)
	return Duel.GetTurnCount()~=e:GetHandler():GetTurnID() or e:GetHandler():IsReason(REASON_RETURN)
end
--condition of checking battle phase availability
function Auxiliary.bpcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsAbleToEnterBP() or (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE)
end
--condition of free chain effects changing ATK/DEF
function Auxiliary.dscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()~=PHASE_DAMAGE or not Duel.IsDamageCalculated()
end
--flag effect for spell counter
function Auxiliary.chainreg(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():GetFlagEffect(FLAG_ID_CHAINING)==0 then
		e:GetHandler():RegisterFlagEffect(FLAG_ID_CHAINING,RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET+RESET_CHAIN,0,1)
	end
end
--default filter for EFFECT_CANNOT_BE_BATTLE_TARGET
function Auxiliary.imval1(e,c)
	return not c:IsImmuneToEffect(e)
end
--filter for EFFECT_INDESTRUCTABLE_EFFECT + self
function Auxiliary.indsval(e,re,rp)
	return rp==e:GetHandlerPlayer()
end
--filter for EFFECT_INDESTRUCTABLE_EFFECT + opponent
function Auxiliary.indoval(e,re,rp)
	return rp==1-e:GetHandlerPlayer()
end
--filter for EFFECT_CANNOT_BE_EFFECT_TARGET + self
function Auxiliary.tgsval(e,re,rp)
	return rp==e:GetHandlerPlayer()
end
--filter for EFFECT_CANNOT_BE_EFFECT_TARGET + opponent
function Auxiliary.tgoval(e,re,rp)
	return rp==1-e:GetHandlerPlayer()
end
--filter for non-zero ATK
function Auxiliary.nzatk(c)
	return c:IsFaceup() and c:GetAttack()>0
end
--filter for non-zero DEF
function Auxiliary.nzdef(c)
	return c:IsFaceup() and c:GetDefense()>0
end
--flag effect for summon/sp_summon turn
function Auxiliary.sumreg(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	local code=e:GetLabel()
	while tc do
		if tc:GetOriginalCode()==code then
			tc:RegisterFlagEffect(code,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
		end
		tc=eg:GetNext()
	end
end
--for EVENT_BE_MATERIAL effect releated to the summoned monster
function Auxiliary.CreateMaterialReasonCardRelation(c,te)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_BE_MATERIAL)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetOperation(Auxiliary.MaterialReasonCardReg)
	e1:SetLabelObject(te)
	c:RegisterEffect(e1)
end
function Auxiliary.MaterialReasonCardReg(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local te=e:GetLabelObject()
	c:GetReasonCard():CreateEffectRelation(te)
end
--the player tp has token on the field
function Auxiliary.tkfcon(e,tp)
	if tp==nil and e~=nil then tp=e:GetHandlerPlayer() end
	return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_ONFIELD,0,1,nil,TYPE_TOKEN)
end
--effects inflicting damage to tp
function Auxiliary.damcon1(e,tp,eg,ep,ev,re,r,rp)
	local e1=Duel.IsPlayerAffectedByEffect(tp,EFFECT_REVERSE_DAMAGE)
	local e2=Duel.IsPlayerAffectedByEffect(tp,EFFECT_REVERSE_RECOVER)
	local rd=e1 and not e2
	local rr=not e1 and e2
	local ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
	if ex and (cp==tp or cp==PLAYER_ALL) and not rd and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_NO_EFFECT_DAMAGE) then
		return true
	end
	ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_RECOVER)
	return ex and (cp==tp or cp==PLAYER_ALL) and rr and not Duel.IsPlayerAffectedByEffect(tp,EFFECT_NO_EFFECT_DAMAGE)
end
--filter for the immune effect of qli monsters
function Auxiliary.qlifilter(e,te)
	if te:IsActiveType(TYPE_MONSTER) and te:IsActivated() then
		local lv=e:GetHandler():GetLevel()
		local ec=te:GetOwner()
		if ec:IsType(TYPE_LINK) then
			return false
		elseif ec:IsType(TYPE_XYZ) then
			return ec:GetOriginalRank()<lv
		else
			return ec:GetOriginalLevel()<lv
		end
	else
		return false
	end
end
--sp_summon condition for gladiator beast monsters
function Auxiliary.gbspcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local typ=c:GetSpecialSummonInfo(SUMMON_INFO_TYPE)
	return c:IsSummonType(SUMMON_VALUE_GLADIATOR) or (typ&TYPE_MONSTER~=0 and c:IsSpecialSummonSetCard(0x1019))
end
--sp_summon condition for evolsaur monsters
function Auxiliary.evospcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local typ=c:GetSpecialSummonInfo(SUMMON_INFO_TYPE)
	return c:IsSummonType(SUMMON_VALUE_EVOLTILE) or (typ&TYPE_MONSTER~=0 and c:IsSpecialSummonSetCard(0x304e))
end
--filter for necro_valley test
function Auxiliary.NecroValleyFilter(f)
	return  function(target,...)
				return (not f or f(target,...)) and not target:IsHasEffect(EFFECT_NECRO_VALLEY)
			end
end
--Necrovalley test for effect with not certain target or not certain action
function Auxiliary.NecroValleyNegateCheck(v)
	if not Duel.IsChainDisablable(0) then return false end
	local g=Group.CreateGroup()
	if Auxiliary.GetValueType(v)=="Card" then g:AddCard(v) end
	if Auxiliary.GetValueType(v)=="Group" then g:Merge(v) end
	if g:IsExists(Card.IsHasEffect,1,nil,EFFECT_NECRO_VALLEY) then
		Duel.NegateEffect(0)
		return true
	end
	return false
end
--Ursarctic common summon from hand effect
function Auxiliary.AddUrsarcticSpSummonEffect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCondition(Auxiliary.UrsarcticSpSummonCondition)
	e1:SetCost(Auxiliary.UrsarcticSpSummonCost)
	e1:SetTarget(Auxiliary.UrsarcticSpSummonTarget)
	e1:SetOperation(Auxiliary.UrsarcticSpSummonOperation)
	c:RegisterEffect(e1)
	return e1
end
function Auxiliary.UrsarcticSpSummonCondition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end
function Auxiliary.UrsarcticReleaseFilter(c)
	return c:IsLevelAbove(7) and c:IsLocation(LOCATION_HAND)
end
function Auxiliary.UrsarcticExCostFilter(c,tp)
	return c:IsAbleToRemoveAsCost() and (c:IsHasEffect(16471775,tp) or c:IsHasEffect(89264428,tp))
end
function Auxiliary.UrsarcticSpSummonCost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.GetReleaseGroup(tp,true):Filter(Auxiliary.UrsarcticReleaseFilter,e:GetHandler())
	local g2=Duel.GetMatchingGroup(Auxiliary.UrsarcticExCostFilter,tp,LOCATION_GRAVE,0,nil,tp)
	g1:Merge(g2)
	if chk==0 then return g1:GetCount()>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local tc=g1:Select(tp,1,1,nil):GetFirst()
	local te=tc:IsHasEffect(16471775,tp) or tc:IsHasEffect(89264428,tp)
	if te then
		te:UseCountLimit(tp)
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	else
		Duel.Release(tc,REASON_COST)
	end
end
function Auxiliary.UrsarcticSpSummonTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function Auxiliary.UrsarcticSpSummonOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(Auxiliary.UrsarcticSpSummonLimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function Auxiliary.UrsarcticSpSummonLimit(e,c)
	return c:IsLevel(0)
end
--Drytron common summon effect
function Auxiliary.AddDrytronSpSummonEffect(c,func)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCost(Auxiliary.DrytronSpSummonCost)
	e1:SetTarget(Auxiliary.DrytronSpSummonTarget)
	e1:SetOperation(Auxiliary.DrytronSpSummonOperation(func))
	c:RegisterEffect(e1)
	Duel.AddCustomActivityCounter(97148796,ACTIVITY_SPSUMMON,Auxiliary.DrytronCounterFilter)
	return e1
end
function Auxiliary.DrytronCounterFilter(c)
	return not c:IsSummonableCard()
end
function Auxiliary.DrytronCostFilter(c,tp)
	return (c:IsSetCard(0x154) or c:IsType(TYPE_RITUAL)) and c:IsType(TYPE_MONSTER) and Duel.GetMZoneCount(tp,c)>0
		and (c:IsControler(tp) or c:IsFaceup())
end
function Auxiliary.DrytronExtraCostFilter(c,tp)
	return c:IsAbleToRemove() and c:IsHasEffect(89771220,tp)
end
function Auxiliary.DrytronSpSummonCost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(100)
	local g1=Duel.GetReleaseGroup(tp,true):Filter(Auxiliary.DrytronCostFilter,e:GetHandler(),tp)
	local g2=Duel.GetMatchingGroup(Auxiliary.DrytronExtraCostFilter,tp,LOCATION_GRAVE,0,nil,tp)
	g1:Merge(g2)
	if chk==0 then return #g1>0 and Duel.GetCustomActivityCount(97148796,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetTargetRange(1,0)
	e1:SetTarget(Auxiliary.DrytronSpSummonLimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--cant special summon summonable card check
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(97148796)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e2:SetTargetRange(1,0)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local rg=g1:Select(tp,1,1,nil)
	local tc=rg:GetFirst()
	local te=tc:IsHasEffect(89771220,tp)
	if te then
		te:UseCountLimit(tp)
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	else
		Auxiliary.UseExtraReleaseCount(rg,tp)
		Duel.Release(tc,REASON_COST)
	end
end
function Auxiliary.DrytronSpSummonLimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsSummonableCard() and c:GetOriginalType()&(TYPE_SPELL|TYPE_TRAP|TYPE_TRAPMONSTER)==0
end
function Auxiliary.DrytronSpSummonTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	local res=e:GetLabel()==100 or Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	if chk==0 then
		e:SetLabel(0)
		return res and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,true,POS_FACEUP_DEFENSE)
	end
	e:SetLabel(0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function Auxiliary.DrytronSpSummonOperation(func)
	return  function(e,tp,eg,ep,ev,re,r,rp)
				local c=e:GetHandler()
				if not c:IsRelateToEffect(e) then return end
				if Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP_DEFENSE)~=0 then
					c:CompleteProcedure()
					func(e,tp)
				end
			end
end
---The `nolimit` parameter for Special Summon effects of Drytron cards
---@param c Card
---@return boolean
function Auxiliary.DrytronSpSummonType(c)
	return c:IsType(TYPE_SPSUMMON)
end
---The `nolimit` parameter for Special Summon effects of Dragon, Xyz monsters where Soul Drain Dragon is available
---(Soul Drain Dragon, Level 8/LIGHT/Dragon/4000/0)
---@param c Card
---@return boolean
function Auxiliary.DragonXyzSpSummonType(c)
	return c:GetOriginalCode()==55735315
end
---The `nolimit` parameter for Special Summon effects of Triamid cards
---@param c Card
---@return boolean
function Auxiliary.TriamidSpSummonType(c)
	return c:IsType(TYPE_SPSUMMON)
end
--additional destroy effect for the Labrynth field
function Auxiliary.LabrynthDestroyOp(e,tp,res)
	local c=e:GetHandler()
	local chk=not c:IsStatus(STATUS_ACT_FROM_HAND) and c:IsSetCard(0x117e) and c:GetType()==TYPE_TRAP and e:IsHasType(EFFECT_TYPE_ACTIVATE)
	local exc=nil
	if c:IsStatus(STATUS_LEAVE_CONFIRMED) then exc=c end
	local te=Duel.IsPlayerAffectedByEffect(tp,33407125)
	if chk and te
		and Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,exc)
		and Duel.SelectYesNo(tp,Auxiliary.Stringid(33407125,0)) then
		if res>0 then Duel.BreakEffect() end
		Duel.Hint(HINT_CARD,0,33407125)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local dg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,exc)
		Duel.HintSelection(dg)
		Duel.Destroy(dg,REASON_EFFECT)
		te:UseCountLimit(tp)
	end
end
--shortcut for Gizmek cards
function Auxiliary.AtkEqualsDef(c)
	if not c:IsType(TYPE_MONSTER) or c:IsType(TYPE_LINK) then return false end
	if c:GetAttack()~=c:GetDefense() then return false end
	return c:IsLocation(LOCATION_MZONE) or c:GetTextAttack()>=0 and c:GetTextDefense()>=0
end
--shortcut for self-banish costs
function Auxiliary.bfgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
--check for cards with different names
function Auxiliary.dncheck(g)
	return g:GetClassCount(Card.GetCode)==#g
end
--check for cards with different levels
function Auxiliary.dlvcheck(g)
	return g:GetClassCount(Card.GetLevel)==#g
end
--check for cards with different ranks
function Auxiliary.drkcheck(g)
	return g:GetClassCount(Card.GetRank)==#g
end
--check for cards with different links
function Auxiliary.dlkcheck(g)
	return g:GetClassCount(Card.GetLink)==#g
end
--check for cards with different attributes
function Auxiliary.dabcheck(g)
	return g:GetClassCount(Card.GetAttribute)==#g
end
--check for cards with different races
function Auxiliary.drccheck(g)
	return g:GetClassCount(Card.GetRace)==#g
end
--check for group with 2 cards, each card match f with a1/a2 as argument
function Auxiliary.gfcheck(g,f,a1,a2)
	if #g~=2 then return false end
	local c1=g:GetFirst()
	local c2=g:GetNext()
	return f(c1,a1) and f(c2,a2) or f(c2,a1) and f(c1,a2)
end
--check for group with 2 cards, each card match f1 with a1, f2 with a2 as argument
function Auxiliary.gffcheck(g,f1,a1,f2,a2)
	if #g~=2 then return false end
	local c1=g:GetFirst()
	local c2=g:GetNext()
	return f1(c1,a1) and f2(c2,a2) or f1(c2,a1) and f2(c1,a2)
end
function Auxiliary.mzctcheck(g,tp)
	return Duel.GetMZoneCount(tp,g)>0
end
---Check if there is space in mzone after tp releases g by reason
---@param g Group
---@param tp integer
---@param reason? integer
---@return boolean
function Auxiliary.mzctcheckrel(g,tp,reason)
	reason=reason or REASON_COST
	return Duel.GetMZoneCount(tp,g)>0 and Duel.CheckReleaseGroupEx(tp,Auxiliary.IsInGroup,#g,reason,false,nil,g)
end
--used for "except this card"
function Auxiliary.ExceptThisCard(e)
	local c=e:GetHandler()
	if c:IsRelateToChain() then return c else return nil end
end
--used for multi-linked zone(zone linked by two or more link monsters)
function Auxiliary.GetMultiLinkedZone(tp)
	local f=function(c)
		return c:IsFaceup() and c:IsType(TYPE_LINK)
	end
	local lg=Duel.GetMatchingGroup(f,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local multi_linked_zone=0
	local single_linked_zone=0
	for tc in Auxiliary.Next(lg) do
		local zone=tc:GetLinkedZone(tp)&0x7f
		multi_linked_zone=single_linked_zone&zone|multi_linked_zone
		single_linked_zone=single_linked_zone~zone
	end
	return multi_linked_zone
end
Auxiliary.SubGroupCaptured=nil
function Auxiliary.CheckGroupRecursive(c,sg,g,f,min,max,ext_params)
	sg:AddCard(c)
	if Auxiliary.GCheckAdditional and not Auxiliary.GCheckAdditional(sg,c,g) then
		sg:RemoveCard(c)
		return false
	end
	local res=(#sg>=min and #sg<=max and f(sg,table.unpack(ext_params)))
		or (#sg<max and g:IsExists(Auxiliary.CheckGroupRecursive,1,sg,sg,g,f,min,max,ext_params))
	sg:RemoveCard(c)
	return res
end
function Auxiliary.CheckGroupRecursiveCapture(c,sg,g,f,min,max,ext_params)
	sg:AddCard(c)
	if Auxiliary.GCheckAdditional and not Auxiliary.GCheckAdditional(sg,c,g) then
		sg:RemoveCard(c)
		return false
	end
	local res=#sg>=min and #sg<=max and f(sg,table.unpack(ext_params))
	if res then
		Auxiliary.SubGroupCaptured:Clear()
		Auxiliary.SubGroupCaptured:Merge(sg)
	else
		res=#sg<max and g:IsExists(Auxiliary.CheckGroupRecursiveCapture,1,sg,sg,g,f,min,max,ext_params)
	end
	sg:RemoveCard(c)
	return res
end
---
---@param g Group
---@param f function
---@param min? integer
---@param max? integer
---@param ... any
---@return boolean
function Group.CheckSubGroup(g,f,min,max,...)
	min=min or 1
	max=max or #g
	if min>max then return false end
	local ext_params={...}
	local sg=Duel.GrabSelectedCard()
	if #sg>max or #(g+sg)<min then return false end
	if #sg==max and (not f(sg,...) or Auxiliary.GCheckAdditional and not Auxiliary.GCheckAdditional(sg,nil,g)) then return false end
	if #sg>=min and #sg<=max and f(sg,...) and (not Auxiliary.GCheckAdditional or Auxiliary.GCheckAdditional(sg,nil,g)) then return true end
	local eg=g:Clone()
	for c in Auxiliary.Next(g-sg) do
		if Auxiliary.CheckGroupRecursive(c,sg,eg,f,min,max,ext_params) then return true end
		eg:RemoveCard(c)
	end
	return false
end
---
---@param g Group
---@param tp integer
---@param f function
---@param cancelable boolean
---@param min? integer
---@param max? integer
---@param ... any
---@return Group
function Group.SelectSubGroup(g,tp,f,cancelable,min,max,...)
	Auxiliary.SubGroupCaptured=Group.CreateGroup()
	min=min or 1
	max=max or #g
	local ext_params={...}
	local sg=Group.CreateGroup()
	local fg=Duel.GrabSelectedCard()
	if #fg>max or min>max or #(g+fg)<min then return nil end
	for tc in Auxiliary.Next(fg) do
		fg:SelectUnselect(sg,tp,false,false,min,max)
	end
	sg:Merge(fg)
	local finish=(#sg>=min and #sg<=max and f(sg,...))
	while #sg<max do
		local cg=Group.CreateGroup()
		local eg=g:Clone()
		for c in Auxiliary.Next(g-sg) do
			if not cg:IsContains(c) then
				if Auxiliary.CheckGroupRecursiveCapture(c,sg,eg,f,min,max,ext_params) then
					cg:Merge(Auxiliary.SubGroupCaptured)
				else
					eg:RemoveCard(c)
				end
			end
		end
		cg:Sub(sg)
		finish=(#sg>=min and #sg<=max and f(sg,...))
		if #cg==0 then break end
		local cancel=not finish and cancelable
		local tc=cg:SelectUnselect(sg,tp,finish,cancel,min,max)
		if not tc then break end
		if not fg:IsContains(tc) then
			if not sg:IsContains(tc) then
				sg:AddCard(tc)
				if #sg==max then finish=true end
			else
				sg:RemoveCard(tc)
			end
		elseif cancelable then
			return nil
		end
	end
	if finish then
		return sg
	else
		return nil
	end
end
---Create a table of filter functions
---@param f function
---@param list table
---@return table
function Auxiliary.CreateChecks(f,list)
	local checks={}
	for i=1,#list do
		checks[i]=function(c) return f(c,list[i]) end
	end
	return checks
end
function Auxiliary.CheckGroupRecursiveEach(c,sg,g,f,checks,ext_params)
	if not checks[1+#sg](c) then
		return false
	end
	sg:AddCard(c)
	if Auxiliary.GCheckAdditional and not Auxiliary.GCheckAdditional(sg,c,g) then
		sg:RemoveCard(c)
		return false
	end
	local res
	if #sg==#checks then
		res=f(sg,table.unpack(ext_params))
	else
		res=g:IsExists(Auxiliary.CheckGroupRecursiveEach,1,sg,sg,g,f,checks,ext_params)
	end
	sg:RemoveCard(c)
	return res
end
---
---@param g Group
---@param checks table
---@param f? function
---@param ... any
---@return boolean
function Group.CheckSubGroupEach(g,checks,f,...)
	if f==nil then f=Auxiliary.TRUE end
	if #g<#checks then return false end
	local ext_params={...}
	local sg=Group.CreateGroup()
	return g:IsExists(Auxiliary.CheckGroupRecursiveEach,1,sg,sg,g,f,checks,ext_params)
end
---
---@param g Group
---@param tp integer
---@param checks table
---@param cancelable? boolean
---@param f? function
---@param ... any
---@return Group
function Group.SelectSubGroupEach(g,tp,checks,cancelable,f,...)
	if cancelable==nil then cancelable=false end
	if f==nil then f=Auxiliary.TRUE end
	local ct=#checks
	local ext_params={...}
	local sg=Group.CreateGroup()
	local finish=false
	while #sg<ct do
		local cg=g:Filter(Auxiliary.CheckGroupRecursiveEach,sg,sg,g,f,checks,ext_params)
		if #cg==0 then break end
		local tc=cg:SelectUnselect(sg,tp,false,cancelable,ct,ct)
		if not tc then break end
		if not sg:IsContains(tc) then
			sg:AddCard(tc)
			if #sg==ct then finish=true end
		else
			sg:Clear()
		end
	end
	if finish then
		return sg
	else
		return nil
	end
end
--for effects that player usually select card from field, avoid showing panel
function Auxiliary.SelectCardFromFieldFirst(tp,f,player,s,o,min,max,ex,...)
	local ext_params={...}
	local g=Duel.GetMatchingGroup(f,player,s,o,ex,table.unpack(ext_params))
	local fg=g:Filter(Card.IsOnField,nil)
	g:Sub(fg)
	if #fg>=min and #g>0 then
		local last_hint=Duel.GetLastSelectHint(tp)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FIELD_FIRST)
		local sg=fg:CancelableSelect(tp,min,max,nil)
		if sg then
			return sg
		else
			Duel.Hint(HINT_SELECTMSG,tp,last_hint)
		end
	end
	return Duel.SelectMatchingCard(tp,f,player,s,o,min,max,ex,table.unpack(ext_params))
end
function Auxiliary.SelectTargetFromFieldFirst(tp,f,player,s,o,min,max,ex,...)
	local ext_params={...}
	local g=Duel.GetMatchingGroup(f,player,s,o,ex,table.unpack(ext_params)):Filter(Card.IsCanBeEffectTarget,nil)
	local fg=g:Filter(Card.IsOnField,nil)
	g:Sub(fg)
	if #fg>=min and #g>0 then
		local last_hint=Duel.GetLastSelectHint(tp)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FIELD_FIRST)
		local sg=fg:CancelableSelect(tp,min,max,nil)
		if sg then
			Duel.SetTargetCard(sg)
			return sg
		else
			Duel.Hint(HINT_SELECTMSG,tp,last_hint)
		end
	end
	return Duel.SelectTarget(tp,f,player,s,o,min,max,ex,table.unpack(ext_params))
end
--condition of "negate activation and banish"
function Auxiliary.nbcon(tp,re)
	local rc=re:GetHandler()
	return Duel.IsPlayerCanRemove(tp)
		and (not rc:IsRelateToEffect(re) or rc:IsAbleToRemove())
end
function Auxiliary.nbtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Auxiliary.nbcon(tp,re) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
	if re:GetActivateLocation()==LOCATION_GRAVE then
		e:SetCategory(e:GetCategory()|CATEGORY_GRAVE_ACTION)
	else
		e:SetCategory(e:GetCategory()&~CATEGORY_GRAVE_ACTION)
	end
end
--condition of "negate activation and return to deck"
function Auxiliary.ndcon(tp,re)
	local rc=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) or not rc:IsRelateToEffect(re) or rc:IsAbleToDeck()
end
--return the global index of the zone in (p,loc,seq)
function Auxiliary.SequenceToGlobal(p,loc,seq)
	if p~=0 and p~=1 then
		return 0
	end
	if loc==LOCATION_MZONE then
		if seq<=6 then
			return 0x0001<<(16*p+seq)
		else
			return 0
		end
	elseif loc == LOCATION_SZONE then
		if seq<=4 then
			return 0x0100<<(16*p+seq)
		else
			return 0
		end
	else
		return 0
	end
end
--use the count limit of Lair of Darkness if the tributes are not selected by Duel.SelectReleaseGroup
function Auxiliary.UseExtraReleaseCount(g,tp)
	local eg=g:Filter(Auxiliary.ExtraReleaseFilter,nil,tp)
	for ec in Auxiliary.Next(eg) do
		local te=ec:IsHasEffect(EFFECT_EXTRA_RELEASE_NONSUM,tp)
		if te then te:UseCountLimit(tp) end
	end
end
function Auxiliary.ExtraReleaseFilter(c,tp)
	return c:IsControler(1-tp) and c:IsHasEffect(EFFECT_EXTRA_RELEASE_NONSUM,tp)
end
--
function Auxiliary.GetCappedLevel(c)
	local lv=c:GetLevel()
	if lv>MAX_PARAMETER then
		return MAX_PARAMETER
	else
		return lv
	end
end
--
function Auxiliary.GetCappedXyzLevel(c)
	local lv=c:GetLevel()
	if lv>MAX_XYZ_LEVEL then
		return MAX_XYZ_LEVEL
	else
		return lv
	end
end
--
function Auxiliary.GetCappedAttack(c)
	local x=c:GetAttack()
	if x>MAX_PARAMETER then
		return MAX_PARAMETER
	else
		return x
	end
end
--when this card is sent to grave, record the reason effect
--to check whether the reason effect do something simultaneously
--so the "while this card is in your GY" condition isn't met
function Auxiliary.AddThisCardInGraveAlreadyCheck(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCondition(Auxiliary.ThisCardInGraveAlreadyCheckReg)
	c:RegisterEffect(e1)
	return e1
end
function Auxiliary.ThisCardInGraveAlreadyCheckReg(e,tp,eg,ep,ev,re,r,rp)
	--condition of continous effect will be checked before other effects
	if re==nil then return false end
	if e:GetLabelObject()~=nil then return false end
	if (r&REASON_EFFECT)>0 then
		e:SetLabelObject(re)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_CHAIN_END)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetOperation(Auxiliary.ThisCardInGraveAlreadyReset1)
		e1:SetLabelObject(e)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EVENT_BREAK_EFFECT)
		e2:SetOperation(Auxiliary.ThisCardInGraveAlreadyReset2)
		e2:SetReset(RESET_CHAIN)
		e2:SetLabelObject(e1)
		Duel.RegisterEffect(e2,tp)
	elseif (r&REASON_MATERIAL)>0 or not re:IsActivated() and (r&REASON_COST)>0 then
		e:SetLabelObject(re)
		local reset_event=EVENT_SPSUMMON
		if re:GetCode()~=EFFECT_SPSUMMON_PROC then reset_event=EVENT_SUMMON end
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(reset_event)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetOperation(Auxiliary.ThisCardInGraveAlreadyReset1)
		e1:SetLabelObject(e)
		Duel.RegisterEffect(e1,tp)
	end
	return false
end
function Auxiliary.ThisCardInGraveAlreadyReset1(e)
	--this will run after EVENT_SPSUMMON_SUCCESS
	e:GetLabelObject():SetLabelObject(nil)
	e:Reset()
end
function Auxiliary.ThisCardInGraveAlreadyReset2(e)
	local e1=e:GetLabelObject()
	e1:GetLabelObject():SetLabelObject(nil)
	e1:Reset()
	e:Reset()
end
--Player p place g on the top of Deck in any order
function Auxiliary.PlaceCardsOnDeckTop(p,g,reason)
	if reason==nil then reason=REASON_EFFECT end
	Duel.SendtoDeck(g,nil,SEQ_DECKTOP,reason)
	local rg=Duel.GetOperatedGroup()
	local og=rg:Filter(Card.IsLocation,nil,LOCATION_DECK)
	local ct1=og:FilterCount(Card.IsControler,nil,p)
	local ct2=og:FilterCount(Card.IsControler,nil,1-p)
	if ct1>1 then
		Duel.SortDecktop(p,p,ct1)
	end
	if ct2>1 then
		Duel.SortDecktop(p,1-p,ct2)
	end
	return #rg
end
--Player p place g on the bottom of Deck in any order
function Auxiliary.PlaceCardsOnDeckBottom(p,g,reason)
	if reason==nil then reason=REASON_EFFECT end
	Duel.SendtoDeck(g,nil,SEQ_DECKTOP,reason)
	local rg=Duel.GetOperatedGroup()
	local og=rg:Filter(Card.IsLocation,nil,LOCATION_DECK)
	local ct1=og:FilterCount(Card.IsControler,nil,p)
	local ct2=og:FilterCount(Card.IsControler,nil,1-p)
	if ct1>0 then
		if ct1>1 then
			Duel.SortDecktop(p,p,ct1)
		end
		for i=1,ct1 do
			local tc=Duel.GetDecktopGroup(p,1):GetFirst()
			Duel.MoveSequence(tc,SEQ_DECKBOTTOM)
		end
	end
	if ct2>0 then
		if ct2>1 then
			Duel.SortDecktop(p,1-p,ct2)
		end
		for i=1,ct2 do
			local tc=Duel.GetDecktopGroup(1-p,1):GetFirst()
			Duel.MoveSequence(tc,SEQ_DECKBOTTOM)
		end
	end
	return #rg
end
--The event is triggered multiple times in a chain
--but only 1 event with EVENT_CUSTOM+code will be triggered at EVENT_CHAIN_END, or immediately if not in chain
--NOTE: re,r,rp,ep,ev of that custom event ARE NOT releated to the real event that trigger this custom event
function Auxiliary.RegisterMergedDelayedEvent(c,code,event,g)
	local mt=getmetatable(c)
	if mt[event]==true then return end
	mt[event]=true
	if not g then g=Group.CreateGroup() end
	g:KeepAlive()
	local ge1=Effect.CreateEffect(c)
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(event)
	ge1:SetLabel(code)
	ge1:SetLabelObject(g)
	ge1:SetOperation(Auxiliary.MergedDelayEventCheck1)
	Duel.RegisterEffect(ge1,0)
	local ge2=ge1:Clone()
	ge2:SetCode(EVENT_CHAIN_END)
	ge2:SetOperation(Auxiliary.MergedDelayEventCheck2)
	Duel.RegisterEffect(ge2,0)
end
function Auxiliary.MergedDelayEventCheck1(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	g:Merge(eg)
	if Duel.GetCurrentChain()==0 and not Duel.CheckEvent(EVENT_CHAIN_END) then
		local _eg=g:Clone()
		Duel.RaiseEvent(_eg,EVENT_CUSTOM+e:GetLabel(),re,r,rp,ep,ev)
		g:Clear()
	end
end
function Auxiliary.MergedDelayEventCheck2(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if #g>0 then
		local _eg=g:Clone()
		Duel.RaiseEvent(_eg,EVENT_CUSTOM+e:GetLabel(),re,r,rp,ep,ev)
		g:Clear()
	end
end
--Once the card has been moved to the public area, it should be listened to again
Auxiliary.merge_single_effect_codes={}
function Auxiliary.RegisterMergedDelayedEvent_ToSingleCard(c,code,events)
	local g=Group.CreateGroup()
	g:KeepAlive()
	local mt=getmetatable(c)
	local seed=0
	if type(events) == "table" then
		for _, event in ipairs(events) do
			seed = seed + event
		end
	else
		seed = events
	end
	while(mt[seed]==true) do
		seed = seed + 1
	end
	mt[seed]=true
	local event_code_single = (code ~ (seed << 16)) | EVENT_CUSTOM
	if type(events) == "table" then
		for _, event in ipairs(events) do
			Auxiliary.RegisterMergedDelayedEvent_ToSingleCard_AddOperation(c,g,event,event_code_single)
		end
	else
		Auxiliary.RegisterMergedDelayedEvent_ToSingleCard_AddOperation(c,g,events,event_code_single)
	end
	--listened to again
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_SET_AVAILABLE)
	e3:SetCode(EVENT_MOVE)
	e3:SetLabel(event_code_single)
	e3:SetLabelObject(g)
	e3:SetOperation(Auxiliary.ThisCardMovedToPublicResetCheck_ToSingleCard)
	c:RegisterEffect(e3)
	Auxiliary.merge_single_effect_codes[event_code_single]=g
	--use global effect to raise event for face-down cards
	if not Auxiliary.merge_single_global_check then
		Auxiliary.merge_single_global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_CHAIN_END)
		ge1:SetOperation(Auxiliary.RegisterMergedDelayedEvent_ToSingleCard_RaiseEvent)
		Duel.RegisterEffect(ge1,0)
	end
	return event_code_single
end
function Auxiliary.RegisterMergedDelayedEvent_ToSingleCard_AddOperation(c,g,event,event_code_single)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(event)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_SET_AVAILABLE)
	e1:SetRange(0xff)
	e1:SetLabel(event_code_single,event)
	e1:SetLabelObject(g)
	e1:SetOperation(Auxiliary.MergedDelayEventCheck1_ToSingleCard)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_CHAIN_END)
	e2:SetOperation(Auxiliary.MergedDelayEventCheck2_ToSingleCard)
	c:RegisterEffect(e2)
end
function Auxiliary.ThisCardMovedToPublicResetCheck_ToSingleCard(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetOwner()
	local g=e:GetLabelObject()
	if c:IsFaceup() or c:IsPublic() then
		g:Clear()
	end
end
function Auxiliary.MergedDelayEventCheck1_ToSingleCard(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	g:Merge(eg)
	local code,event=e:GetLabel()
	local c=e:GetOwner()
	local mr,meg=Duel.CheckEvent(event,true)
	if mr and meg:IsContains(c) and (c:IsFaceup() or c:IsPublic()) then
		g:Clear()
	end
	if Duel.GetCurrentChain()==0 and #g>0 and not Duel.CheckEvent(EVENT_CHAIN_END) then
		local _eg=g:Clone()
		Duel.RaiseEvent(_eg,code,re,r,rp,ep,ev)
		g:Clear()
	end
end
function Auxiliary.MergedDelayEventCheck2_ToSingleCard(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if Duel.CheckEvent(EVENT_MOVE) then
		local _,meg=Duel.CheckEvent(EVENT_MOVE,true)
		local c=e:GetOwner()
		if meg:IsContains(c) and (c:IsFaceup() or c:IsPublic()) then
			g:Clear()
		end
	end
	if #g>0 then
		local _eg=g:Clone()
		Duel.RaiseEvent(_eg,e:GetLabel(),re,r,rp,ep,ev)
		g:Clear()
	end
end
function Auxiliary.RegisterMergedDelayedEvent_ToSingleCard_RaiseEvent(e,tp,eg,ep,ev,re,r,rp)
	for code,g in pairs(Auxiliary.merge_single_effect_codes) do
		if #g>0 then
			local _eg=g:Clone()
			Duel.RaiseEvent(_eg,code,re,r,rp,ep,ev)
			g:Clear()
		end
	end
end
--B.E.S. remove counter
function Auxiliary.EnableBESRemove(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(10)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_DAMAGE_STEP_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(Auxiliary.RemoveCondtion)
	e1:SetTarget(Auxiliary.RemoveTarget)
	e1:SetOperation(Auxiliary.RemoveOperation)
	c:RegisterEffect(e1)
end
function Auxiliary.RemoveCondtion(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsRelateToBattle()
end
function Auxiliary.RemoveTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	if not e:GetHandler():IsCanRemoveCounter(tp,0x1f,1,REASON_EFFECT) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
	end
end
function Auxiliary.RemoveOperation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		if c:IsCanRemoveCounter(tp,0x1f,1,REASON_EFFECT) then
			c:RemoveCounter(tp,0x1f,1,REASON_EFFECT)
		else
			Duel.Destroy(c,REASON_EFFECT)
		end
	end
end
--The operation function of "destroy during End Phase"
function Auxiliary.EPDestroyOperation(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if Auxiliary.GetValueType(tc)=="Card" or Auxiliary.GetValueType(tc)=="Group" then
		Duel.Destroy(tc,REASON_EFFECT,LOCATION_GRAVE)
	end
end
--
function Auxiliary.NegateSummonCondition()
	return Duel.GetReadyChain()==0
end
---Check if all cards in g have the same Attribute/Race
---@param g Group
---@param f function Like Card.GetAttribute, must return binary value
---@return boolean
function Auxiliary.SameValueCheck(g,f)
	if #g<=1 then return true end
	if #g==2 then return f(g:GetFirst())&f(g:GetNext())~=0 end
	local tc=g:GetFirst()
	local v=f(tc)
	tc=g:GetNext()
	while tc do
		v=v&f(tc)
		if v==0 then return false end
		tc=g:GetNext()
	end
	return v~=0
end
---
---@param tp integer
---@return boolean
function Auxiliary.IsPlayerCanNormalDraw(tp)
	return Duel.GetDrawCount(tp)>0 and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0
		and Duel.GetFlagEffect(tp,FLAG_ID_NO_NORMAL_DRAW)==0
end
---
---@param e Effect
---@param tp integer
---@param property? integer
function Auxiliary.GiveUpNormalDraw(e,tp,property)
	property=property or 0
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET|property)
	e1:SetCode(EFFECT_DRAW_COUNT)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_DRAW)
	e1:SetValue(0)
	Duel.RegisterEffect(e1,tp)
	Duel.RegisterFlagEffect(tp,FLAG_ID_NO_NORMAL_DRAW,RESET_PHASE+PHASE_DRAW,property,1)
end
---Add EFFECT_TYPE_ACTIVATE effect to Equip Spell Cards
---@param c Card
---@param is_self boolean
---@param is_opponent boolean
---@param filter function
---@param eqlimit function|nil
---@param pause? boolean
---@param skip_target? boolean
function Auxiliary.AddEquipSpellEffect(c,is_self,is_opponent,filter,eqlimit,pause,skip_target)
	local value=(type(eqlimit)=="function") and eqlimit or 1
	if pause==nil then pause=false end
	if skip_target==nil then skip_target=false end
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_CONTINUOUS_TARGET)
	if not skip_target then
		e1:SetTarget(Auxiliary.EquipSpellTarget(is_self,is_opponent,filter,eqlimit))
	end
	e1:SetOperation(Auxiliary.EquipSpellOperation(eqlimit))
	if not pause then
		c:RegisterEffect(e1)
	end
	--Equip limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EQUIP_LIMIT)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetValue(value)
	c:RegisterEffect(e2)
	return e1
end
function Auxiliary.EquipSpellTarget(is_self,is_opponent,filter,eqlimit)
	local loc1=is_self and LOCATION_MZONE or 0
	local loc2=is_opponent and LOCATION_MZONE or 0
	return function(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() and (not eqlimit or eqlimit(e,chkc)) end
		if chk==0 then return Duel.IsExistingTarget(filter,tp,loc1,loc2,1,nil) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
		Duel.SelectTarget(tp,filter,tp,loc1,loc2,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
	end
end
function Auxiliary.EquipSpellOperation(eqlimit)
	return function (e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local tc=Duel.GetFirstTarget()
		if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() and (not eqlimit or eqlimit(e,tc)) then
			Duel.Equip(tp,c,tc)
		end
	end
end
---If this face-up card would leave the field, banish it instead.
---@param c Card
---@param condition? function
function Auxiliary.AddBanishRedirect(c,condition)
	if type(condition)~="function" then
		condition=Auxiliary.BanishRedirectCondition
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CAN_FORBIDDEN)
	e1:SetCondition(condition)
	e1:SetValue(LOCATION_REMOVED)
	c:RegisterEffect(e1)
end
---
---@param e Effect
function Auxiliary.BanishRedirectCondition(e)
	return e:GetHandler():IsFaceup()
end
---Check if c has a equip card equipped by the effect of itself.
---@param c Card
---@param id integer
---@return boolean
function Auxiliary.IsSelfEquip(c,id)
	return c:GetEquipGroup():IsExists(Auxiliary.SelfEquipFilter,1,nil,id)
end
function Auxiliary.SelfEquipFilter(c,id)
	return c:GetFlagEffect(id)>0
end
---Orcustrated Babel
---@param c Card
---@return boolean
function Auxiliary.OrcustratedBabelFilter(c)
	return c:IsOriginalSetCard(0x11b) and
		(c:IsLocation(LOCATION_MZONE) and c:IsAllTypes(TYPE_LINK+TYPE_MONSTER) or c:IsLocation(LOCATION_GRAVE) and c:IsType(TYPE_MONSTER))
end
---Golden Allure Queen
---@param c Card
---@return boolean
function Auxiliary.GoldenAllureQueenFilter(c)
	return c:IsOriginalSetCard(0x3)
end
--The table of all "become quick effects"
Auxiliary.quick_effect_filter={}
Auxiliary.quick_effect_filter[90351981]=Auxiliary.OrcustratedBabelFilter
Auxiliary.quick_effect_filter[95937545]=Auxiliary.GoldenAllureQueenFilter
---Check if the effect of c becomes a Quick Effect.
---@param c Card
---@param tp integer
---@param code integer
---@return boolean
function Auxiliary.IsCanBeQuickEffect(c,tp,code)
	local filter=Auxiliary.quick_effect_filter[code]
	return Duel.IsPlayerAffectedByEffect(tp,code)~=nil and filter~=nil and filter(c)
end
--
function Auxiliary.DimensionalFissureTarget(e,c)
	return c:GetOriginalType()&TYPE_MONSTER>0 and not c:IsLocation(LOCATION_OVERLAY) and not c:IsType(TYPE_SPELL+TYPE_TRAP)
end
--
function Auxiliary.MimighoulFlipCondition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
---The name of `c` becomes the original name of `tc`
---@param c Card
---@param tc Card
---@param reset? integer defult: RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
---@return Effect
function Auxiliary.BecomeOriginalCode(c,tc,reset)
	reset=reset or (RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	local code=tc:GetOriginalCodeRule()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(code)
	e1:SetReset(reset)
	c:RegisterEffect(e1)
	return e1
end
---@param category integer
---@return function
function Auxiliary.EffectCategoryFilter(category)
	---@param e Effect
	return function (e)
		return e:IsHasCategory(category)
	end
end
---@param flag integer
---@return function
function Auxiliary.EffectPropertyFilter(flag)
	---@param e Effect
	return function (e)
		return e:IsHasProperty(flag)
	end
end
---@param flag integer
---@return function
function Auxiliary.MonsterEffectPropertyFilter(flag)
	---@param e Effect
	return function (e)
		return e:IsHasProperty(flag) and not e:IsHasRange(LOCATION_PZONE)
	end
end

--==============================================
-- 导入 Galaxy 全局规则
--==============================================

Galaxy = {}
gal = Galaxy

--为卡片导入 Galaxy 全局规则 返回 self_table, self_code
function Import()
	self_table.initial_effect = function(c)
		if c.initial then c.initial(c) end
		if c:IsType(GALAXY_TYPE_UNIT) then
			Galaxy.UnitRule(c) --单位通用
		end
		if Galaxy.GlobalRule then return end
		Galaxy.GlobalRule = true
		Galaxy.PlayerRule(c) --玩家规则
		Galaxy.BattleRule(c) --战斗规则
		Galaxy.TacticsRule(c)--战术规则
	end
	return self_table, self_code
end

--单位通用
function Galaxy.UnitRule(c)
	local property = EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE
	--添加特殊召唤手续（强制攻击表示，包含代价检查）
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(property + EFFECT_FLAG_SPSUM_PARAM)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(POS_FACEUP_ATTACK, 0)
	e1:SetCondition(Galaxy.SummonCondition)
	e1:SetOperation(Galaxy.SummonOperation)  --在这里支付代价
	c:RegisterEffect(e1)
	--禁止战斗破坏
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(property + EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--护盾效果显示管理
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCondition(Galaxy.AddShieldDisplay)
	c:RegisterEffect(e3)
	-- 潜行效果显示管理（与护盾类似，确保召唤进入场上的单位若带有潜行则显示客户端提示）
	local e_stealth = e3:Clone()
	e_stealth:SetCondition(Galaxy.AddStealthDisplay)
	c:RegisterEffect(e_stealth)
	--生命值设置
	local e4 = e3:Clone()
	e4:SetCondition(Galaxy.InitializeHp)
	c:RegisterEffect(e4)
	--限制特殊召唤表示：只能以攻击表示进入场上
	local e5 = Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_LIMIT_SPECIAL_SUMMON_POSITION)
	e5:SetProperty(property)
	e5:SetValue(Galaxy.SummonPositionLimit)
	c:RegisterEffect(e5)
	--潜行单位不能成为攻击目标
	local e6 = Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
	e6:SetCondition(Galaxy.StealthAttackLimit)
	e6:SetValue(aux.imval1)
	c:RegisterEffect(e6)
end

--特殊召唤条件：检查场地和代价是否足够
function Galaxy.SummonCondition(e,c)
	if c == nil then return true end
	local tp = c:GetControler()
	if Duel.GetLocationCount(tp, LOCATION_MZONE) == 0 then return false end
	return Duel.CheckSupplyCost(tp, c:GetSupplyCost()) or c:IsHasEffect(EFFECT_FREE_DEPLOY)
end

--特殊召唤操作：在召唤过程中支付代价
function Galaxy.SummonOperation(e,tp,eg,ep,ev,re,r,rp,c)
	local cost = c:GetSupplyCost()
	if c:IsHasEffect(EFFECT_FREE_DEPLOY) then cost = 0 end
	if cost > 0 then Duel.PaySupplyCost(tp, cost) end
end

--特殊召唤表示限制：禁止以守备表示召唤
function Galaxy.SummonPositionLimit(e,c,sump,sumtype,sumpos,targetp)
	return bit.band(sumpos,POS_FACEUP_DEFENSE+POS_FACEDOWN_DEFENSE)~=0
end

--护盾效果显示管理
function Galaxy.AddShieldDisplay(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	if not c:IsLocation(LOCATION_MZONE) or not c:IsHasEffect(EFFECT_SHIELD)
		or c:IsHasEffect(EFFECT_SHIELD_HINT) then return false end
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(10000077,2)) --护盾显示提示文本
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SHIELD_HINT) --护盾显示标识码
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_DISABLE)
	c:RegisterEffect(e1)
	return false
end

--生命值设置
function Galaxy.InitializeHp(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	if not c:IsLocation(LOCATION_MZONE) then return false end
	local hp = c:GetBaseHp()
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_DEFENSE)
	e1:SetValue(hp)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD)
	c:RegisterEffect(e1)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetOperation(Galaxy.CalculateHp)
	e2:SetReset(RESET_EVENT + RESETS_STANDARD)
	e2:SetLabel(hp, hp, 0) -- 存储：原始最大HP，当前最大HP，上次EFFECT_UPDATE_HP效果总和
	e2:SetLabelObject(e1)
	c:RegisterEffect(e2)
	return false
end

--生命值计算
function Galaxy.CalculateHp(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	local now_hp = c:GetHp()
	local hp_max_ori, hp_max_now, last_effect_total = e:GetLabel() -- 获取：原始最大HP，当前最大HP，上次效果总和
	local val = c:GetFlagEffectLabel(FLAG_ADD_HP_IMMEDIATELY_BATTLE)
	if val then
		now_hp = Galaxy.CalculateAddHpImmediately(c, val, now_hp, hp_max_now, REASON_BATTLE, 0)
		if now_hp <= 0 then
			Duel.Destroy(c, REASON_RULE)
			return
		end
		c:ResetFlagEffect(FLAG_ADD_HP_IMMEDIATELY_BATTLE)
	end
	local rev = c:IsHasEffect(EFFECT_REVERSE_UPDATE)
	val = c:GetFlagEffectLabel(FLAG_ADD_HP_IMMEDIATELY_EFFECT)
	if val then
		if rev then val = -val end
		now_hp = Galaxy.CalculateAddHpImmediately(c, val, now_hp, hp_max_now, REASON_EFFECT, rp)
		if now_hp <= 0 then
			Duel.Destroy(c, REASON_RULE)
			return
		end
		c:ResetFlagEffect(FLAG_ADD_HP_IMMEDIATELY_EFFECT)
	end
	local hp_adds = {c:IsHasEffect(EFFECT_UPDATE_HP)}

	-- 确保上次效果总和已初始化
	if not last_effect_total then
		last_effect_total = 0
	end

	-- 计算当前所有EFFECT_UPDATE_HP效果的总和
	local current_effect_total = 0
	if hp_adds[1] then
		for _, ei in ipairs(hp_adds) do
			val = ei:GetValue()
			if type(val) == "function" then
				val = val(ei, c) -- 支持动态值函数
			elseif not val then
				val = 0
			end
			current_effect_total = current_effect_total + val
		end
		if rev then current_effect_total = - current_effect_total end -- 反转效果支持
	end

	-- 计算本次效果变化量：当前总和 - 上次记录的总和
	-- 这样可以正确处理效果的增加、减少和消失
	local effect_delta = current_effect_total - last_effect_total

	if effect_delta ~= 0 then
		-- 应用最大生命值变化
		hp_max_now = hp_max_now + effect_delta

		-- EFFECT_UPDATE_HP分离机制：
		-- 1. 最大生命值变化总是应用
		-- 2. 当前生命值只在效果增加时立即增加
		-- 3. 效果减少时不强制减少当前生命值，除非超过新上限
		if effect_delta > 0 then
			-- 获得增益：当前生命值立即增加相同数值
			now_hp = now_hp + effect_delta
		end
		-- 失去增益：当前生命值保持不变，只有超过新上限时才会被调整

		-- 触发EFFECT_UPDATE_HP变化事件
		Galaxy.RaiseHpEvent(c, effect_delta, true, REASON_EFFECT, rp or 0)

		-- 保存新的状态数据
		e:SetLabel(hp_max_ori, hp_max_now, current_effect_total)
	end

	local pending_hp = c:GetFlagEffectLabel(FLAG_SET_HP_PENDING)
	if pending_hp ~= nil then
		local desired = pending_hp
		if type(desired) ~= "number" then
			desired = tonumber(desired) or 0
		end
		desired = math.floor(desired)
		if desired < 0 then desired = 0 end
		if desired > hp_max_now then desired = hp_max_now end
		now_hp = desired
		c:ResetFlagEffect(FLAG_SET_HP_PENDING)
	end

	-- 三重安全检查确保生命值系统的健壮性：

	-- 检查1：最大生命值 <= 0 导致死亡
	if hp_max_now <= 0 then
		Duel.Destroy(c, REASON_RULE)
		return
	end

	-- 检查2：强制当前生命值不超过最大生命值上限
	if now_hp > hp_max_now then
		now_hp = hp_max_now
	end

	-- 检查3：当前生命值 <= 0 导致死亡
	if now_hp <= 0 then
		Duel.Destroy(c, REASON_RULE)
		return
	end

	e:GetLabelObject():SetValue(now_hp)
end

--计算护盾并触发HP事件
---@param c Card 怪兽卡
---@param val number HP变化量
---@param hp number 当前HP
---@param hp_max number 最大HP
---@param reason integer 原因（REASON_BATTLE 或 REASON_EFFECT）
---@param effect_player integer 效果玩家

function Galaxy.CalculateAddHpImmediately(c, val, hp, hp_max, reason, effect_player)
	local shield = c:IsHasEffect(EFFECT_SHIELD)
	-- 护盾机制：只阻挡伤害（负值），不阻挡治疗（正值）
	if val < 0 and shield then
		shield:Reset() -- 消耗护盾
		Duel.Hint(HINT_CARD, 0, c:GetCode())
		Galaxy.RemoveShieldDisplay(c)
		-- 护盾阻挡伤害，不触发伤害事件
		return hp -- 伤害被完全阻挡，生命值不变
	end

	-- 受到伤害时移除潜行效果
	if val < 0 and c:IsHasEffect(EFFECT_STEALTH) then
		local stealth_effect = c:IsHasEffect(EFFECT_STEALTH)
		if stealth_effect then
			stealth_effect:Reset()
			Galaxy.RemoveStealthDisplay(c)
			--Duel.Hint(HINT_CARD, 0, c:GetCode()) -- 提示潜行被破除
		end
	end

	local old_hp = hp
	hp = hp + val
	if hp > hp_max then
		hp = hp_max
	elseif hp <= 0 then
		hp = 0
	end

	-- 只有当HP实际发生变化时才触发AddHp事件
	local actual_change = hp - old_hp
	if actual_change ~= 0 then
		Galaxy.RaiseHpEvent(c, actual_change, false, reason or REASON_EFFECT, effect_player or 0)
	end

	return hp
end

--玩家规则
function Galaxy.PlayerRule(c)
	local property = EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE
	--怪兽不能变为守备表示
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
	e1:SetProperty(property)
	e1:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	Duel.RegisterEffect(e1, 0)
	--禁止通常召唤
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_CANNOT_SUMMON)
	e2:SetProperty(property + EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1, 1)
	Duel.RegisterEffect(e2, 0)
	--禁止盖放怪兽
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_CANNOT_MSET)
	Duel.RegisterEffect(e3, 0)
	--禁止盖放支援/战术卡
	local e4 = e2:Clone()
	e4:SetCode(EFFECT_CANNOT_SSET)
	Duel.RegisterEffect(e4, 0)
	--先攻玩家的第一次抽卡后给后攻玩家手牌中创建 一次性能量电池(99999999)
	local e5 = Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_PHASE_START + PHASE_DRAW)
	e5:SetCondition(Galaxy.FirstTurnTokenCondition)
	e5:SetOperation(Galaxy.FirstTurnTokenOperation)
	Duel.RegisterEffect(e5, 0)
	--检测到双方卡组里如果有10000101则将它从双方卡组中分别特殊召唤出来
	local e6 = Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PREDRAW)
	e6:SetCondition(Galaxy.CheckDeckForStart)
	e6:SetOperation(Galaxy.SummonForStart)
	Duel.RegisterEffect(e6, 0)
end

-- 检查双方卡组中是否有c10000101
function Galaxy.CheckDeckForStart(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnCount()==1 and
		   (Duel.IsExistingMatchingCard(Card.IsCode,0,LOCATION_EXTRA,0,1,nil,10000101) or
		    Duel.IsExistingMatchingCard(Card.IsCode,1,LOCATION_EXTRA,0,1,nil,10000101))
end

-- 从双方卡组中特殊召唤c10000101
function Galaxy.SummonForStart(e,tp,eg,ep,ev,re,r,rp)
	-- 检查并召唤玩家0的
	local g0 = Duel.GetMatchingGroup(Card.IsCode,0,LOCATION_EXTRA,0,nil,10000101)
	if g0:GetCount()>0 and Duel.GetLocationCount(0,LOCATION_MZONE)>0 then
		local tc = g0:GetFirst()
		Duel.ConfirmCards(0,tc)
		Duel.Hint(HINT_CARD,0,tc:GetCode())
		Duel.SpecialSummon(tc,0,0,0,false,false,POS_FACEUP_ATTACK)
		--给对手增加5lp(set)
		Duel.SetLP(1,Duel.GetLP(1)+5)
	end
	-- 检查并召唤玩家1的
	local g1 = Duel.GetMatchingGroup(Card.IsCode,1,LOCATION_EXTRA,0,nil,10000101)
	if g1:GetCount()>0 and Duel.GetLocationCount(1,LOCATION_MZONE)>0 then
		local tc = g1:GetFirst()
		Duel.ConfirmCards(1,tc)
		Duel.Hint(HINT_CARD,1,tc:GetCode())
		Duel.SpecialSummon(tc,0,1,1,false,false,POS_FACEUP_ATTACK)
		--给对手增加5lp(set)
		Duel.SetLP(0,Duel.GetLP(0)+5)
	end
	--如果有任意玩家携带了c10000101则双方玩家在本局中抽牌阶段额外抽1张卡，只能生效1个。
	if (g0:GetCount()>0 or g1:GetCount()>0) then
		-- 注册全局持续被动效果：双方玩家抽卡阶段额外抽1张卡
		local e_draw = Effect.CreateEffect(e:GetHandler())
		e_draw:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
		e_draw:SetCountLimit(1)
		e_draw:SetCode(EVENT_DRAW)
		e_draw:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
			local turn_player = Duel.GetTurnPlayer()
			-- 当前回合玩家额外抽1张卡
			if Duel.IsPlayerCanDraw(turn_player,1) then
				Duel.Draw(turn_player,1,REASON_EFFECT)
			end
		end)
		Duel.RegisterEffect(e_draw, 0)
	end

	-- 重置效果，避免重复触发
	e:Reset()
end

function Galaxy.FirstTurnTokenCondition(e,tp,eg,ep,ev,re,r,rp)
	--检查是否为先攻玩家的第一次抽卡
	return Duel.GetCurrentPhase() == PHASE_DRAW
end

function Galaxy.FirstTurnTokenOperation(e,tp,eg,ep,ev,re,r,rp)
	--为后攻玩家(1)在手牌中创建 一次性能量电池(99999999)
	local c = Duel.CreateToken(1,99999999)
	Duel.SendtoHand(c, 1, REASON_RULE)
	Duel.ConfirmCards(0, c)
	e:Reset()
end

--战斗规则
function Galaxy.BattleRule(c)
	local property = EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE
	--召唤回合不能攻击
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetProperty(property)
	e1:SetTarget(Galaxy.SummonThisTurn)
	e1:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	Duel.RegisterEffect(e1, 0)
	--战斗结束时处理降低怪兽生命
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BATTLED)
	e2:SetProperty(property)
	e2:SetCondition(Galaxy.ReduceHP)
	Duel.RegisterEffect(e2, 0)
	--不造成战斗伤害
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetProperty(property + EFFECT_FLAG_PLAYER_TARGET)
	e3:SetTargetRange(1, 1)
	e3:SetValue(Galaxy.ChangeBattleDamage)
	Duel.RegisterEffect(e3, 0)
	--优先选择有保护的单位攻击
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e4:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	e4:SetValue(Galaxy.ProtectAttackLimit)
	Duel.RegisterEffect(e4, 0)
	--潜行单位不能成为效果的对象
	local e6 = Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e6:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	e6:SetTarget(Galaxy.StealthEffectTarget)
	-- 只阻止对手成为潜行单位的效果对象，友方仍可选中
	e6:SetValue(Auxiliary.tgoval)
	Duel.RegisterEffect(e6, 0)
	--攻击后移除潜行
	local e7 = Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e7:SetCode(EVENT_ATTACK_ANNOUNCE)
	e7:SetOperation(Galaxy.RemoveStealthAfterAttack)
	Duel.RegisterEffect(e7, 0)
	--发动效果后移除潜行
	local e8 = Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
	e8:SetCode(EVENT_CHAINING)
	e8:SetOperation(Galaxy.RemoveStealthAfterActivation)
	Duel.RegisterEffect(e8, 0)
end

--在本回合召唤
function Galaxy.SummonThisTurn(e,c)
	return not c:IsHasEffect(EFFECT_RUSH) and (c:IsStatus(STATUS_SUMMON_TURN)
		or c:IsStatus(STATUS_FLIP_SUMMON_TURN) or c:IsStatus(STATUS_SPSUMMON_TURN))
end

--伤害步骤结束时处理守备力减少（仅怪兽对怪兽战斗时）
function Galaxy.ReduceHP(e,tp,eg,ep,ev,re,r,rp)
	local atker = Duel.GetAttacker()
	local defer = Duel.GetAttackTarget()
	if not (atker and defer) then return false end
	local atk_dam = defer:GetAttack()
	local def_dam = atker:GetAttack()
	
	-- 检查致命效果：如果攻击者有EFFECT_LETHAL，防御者受到致命伤害
	local atker_has_lethal = atker:IsHasEffect(EFFECT_LETHAL)
	local defer_has_lethal = defer:IsHasEffect(EFFECT_LETHAL)
	
	-- 对攻击者造成伤害（可能是致命的）
	if defer_has_lethal then
		-- 防御者有致命，攻击者受到致命伤害（攻击力 + 目标当前HP，确保击杀）
		local lethal_damage = atk_dam + atker:GetHp()
		Duel.AddHp(atker, -lethal_damage, REASON_BATTLE)
	else
		Duel.AddHp(atker, -atk_dam, REASON_BATTLE)
	end
	
	-- 对防御者造成伤害（可能是致命的）
	if atker_has_lethal then
		-- 攻击者有致命，防御者受到致命伤害（攻击力 + 目标当前HP，确保击杀）
		local lethal_damage = def_dam + defer:GetHp()
		Duel.AddHp(defer, -lethal_damage, REASON_BATTLE)
	else
		Duel.AddHp(defer, -def_dam, REASON_BATTLE)
	end
	
	return false
end

--不造成战斗伤害（如果有攻击目标，说明非直接攻击玩家，阻止伤害）
function Galaxy.ChangeBattleDamage(e,re,dam,r,rp,rc)
	if r & REASON_BATTLE == REASON_BATTLE and Duel.GetAttackTarget() then
		return 0
	end
	return dam
end

--优先选择有保护且没有隐身的单位攻击
function Galaxy.ProtectAttackLimit(e,c)
	if c:IsHasEffect(EFFECT_PROTECT) then
		return false
	end
	local tp = c:GetControler()
	return Duel.IsExistingMatchingCard(Galaxy.ProtectAttackFilter,tp,LOCATION_MZONE,0,1,nil)
end

--filter有保护且没有隐身的单位攻击
function Galaxy.ProtectAttackFilter(c)
	return c:IsHasEffect(EFFECT_PROTECT) and not c:IsHasEffect(EFFECT_STEALTH)
end

--潜行单位不能成为攻击目标
function Galaxy.StealthAttackLimit(e,c)
	if not c then
		c = e:GetHandler()
	end
	return c and c:IsHasEffect(EFFECT_STEALTH)
end

--潜行单位不能成为效果的对象
function Galaxy.StealthEffectTarget(e,c)
	return c:IsHasEffect(EFFECT_STEALTH)
end

--攻击后移除潜行
function Galaxy.RemoveStealthAfterAttack(e,tp,eg,ep,ev,re,r,rp)
	local atker = Duel.GetAttacker()
	if atker and atker:IsHasEffect(EFFECT_STEALTH) then
		local stealth_effect = atker:IsHasEffect(EFFECT_STEALTH)
		if stealth_effect then
			stealth_effect:Reset()
			Galaxy.RemoveStealthDisplay(atker)
		end
	end
end

--发动效果后移除潜行
function Galaxy.RemoveStealthAfterActivation(e,tp,eg,ep,ev,re,r,rp)
	local tc = re:GetHandler()
	if tc and tc:IsHasEffect(EFFECT_STEALTH) and tc:IsLocation(LOCATION_MZONE) then
		local stealth_effect = tc:IsHasEffect(EFFECT_STEALTH)
		if stealth_effect then
			stealth_effect:Reset()
			Galaxy.RemoveStealthDisplay(tc)
		end
	end
end

--战术规则
function Galaxy.TacticsRule(c)
	local property = EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE
	--可以从手卡发动
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e1:SetProperty(property)
	e1:SetTargetRange(LOCATION_HAND, LOCATION_HAND)
	Duel.RegisterEffect(e1, 0)
	--只能在对方回合发动
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_TRIGGER)
	e2:SetProperty(property)
	e2:SetTargetRange(0xff, 0xff)
	e2:SetTarget(Galaxy.TacticsOppoOnly)
	Duel.RegisterEffect(e2, 0)
end

--战术卡只能在对方回合发动
function Galaxy.TacticsOppoOnly(e,c)
	return c:IsType(GALAXY_TYPE_TACTICS) and Duel.GetTurnPlayer() == c:GetControler()
end

--==============================================
-- Galaxy Card 函数
--==============================================

--获取/检查 单位生命值相关
Card.GetHp = Card.GetDefense
Card.GetBaseHp = Card.GetBaseDefense
Card.IsHp = Card.IsDefense
Card.IsHpAbove = Card.IsDefenseAbove
Card.IsHpBelow = Card.IsDefenseBelow
Card.GetOriginalHp = Card.GetTextDefense

-- 新增生命值相关函数
-- 获取最大生命值（包含所有EFFECT_UPDATE_HP效果的动态最大值）
function Card.GetMaxHp(c)
	-- 查找Galaxy.CalculateHp注册的EVENT_ADJUST效果
	local effects = {c:IsHasEffect(EVENT_ADJUST)}
	for _, eff in ipairs(effects) do
		if eff:GetOperation() == Galaxy.CalculateHp then
			local hp_max_ori, hp_max_now, last_effect_total = eff:GetLabel()
			return hp_max_now or c:GetOriginalHp()
		end
	end
	-- 如果没找到HP计算系统，返回基础值basehp
	return c:GetOriginalHp()
end

--获取/检查 补给代价相关
Card.GetSupplyCost = Card.GetLevel
Card.IsSupplyCost = Card.IsLevel
Card.IsSupplyCostAbove = Card.IsLevelAbove
Card.IsSupplyCostBelow = Card.IsLevelBelow
Card.GetOriginalSupplyCost = Card.GetOriginalLevel

--获取/检查 特性(原属性)相关
Card.IsGalaxyProperty = Card.IsAttribute
Card.GetGalaxyProperty = Card.GetAttribute
Card.GetOriginalGalaxyProperty = Card.GetOriginalAttribute

--获取/检查 检查类别(原种族)相关
Card.IsGalaxyCategory = Card.IsRace
Card.GetGalaxyCategory = Card.GetRace
Card.GetOriginalGalaxyCategory = Card.GetOriginalRace

--==============================================
-- Galaxy 函数
--==============================================

--移除护盾显示
function Galaxy.RemoveShieldDisplay(c)
	local shield_display = c:IsHasEffect(EFFECT_SHIELD_HINT)
	if shield_display then
		shield_display:Reset()
	end
end

--潜行效果显示管理
function Galaxy.AddStealthDisplay(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	if not c:IsLocation(LOCATION_MZONE) or not c:IsHasEffect(EFFECT_STEALTH)
		or c:IsHasEffect(EFFECT_STEALTH_HINT) then return false end
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(10000077,3)) --潜行显示提示文本
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_STEALTH_HINT) --潜行显示标识码
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_DISABLE)
	c:RegisterEffect(e1)
	return false
end

--移除潜行显示
function Galaxy.RemoveStealthDisplay(c)
	local stealth_display = c:IsHasEffect(EFFECT_STEALTH_HINT)
	if stealth_display then
		stealth_display:Reset()
	end
end

--立刻增减生命力
function Duel.AddHp(g_c, hp, reason)
	local typ = aux.GetValueType(g_c)
	if typ == "Card" then
		g_c = Group.FromCards(g_c)
	elseif typ ~= "Group" then
		error("parameter 1 should be Card or Group", 2)
	end
	if aux.GetValueType(hp) ~= "number" then error("parameter 2 should be number", 2) end
	local flag = 0
	if aux.GetValueType(reason) ~= "number" then
		error("parameter 3 should be number", 2)
	elseif reason & REASON_BATTLE > 0  then
		flag = FLAG_ADD_HP_IMMEDIATELY_BATTLE
	elseif reason & REASON_EFFECT > 0  then
		flag = FLAG_ADD_HP_IMMEDIATELY_EFFECT
	else
		error("parameter 3 should be REASON_BATTLE or REASON_EFFECT", 2)
	end
	for c in aux.Next(g_c) do
		c:RegisterFlagEffect(flag, 0, EFFECT_FLAG_CANNOT_DISABLE, 1, hp)
	end
end

--直接设置生命力（不触发HP事件）
---@param g_c Card|Group 要设置HP的卡片或卡片组
---@param hp number 要设置的HP值
function Duel.SetHp(g_c, hp)
	local typ = aux.GetValueType(g_c)
	if typ == "Card" then
		g_c = Group.FromCards(g_c)
	elseif typ ~= "Group" then
		error("parameter 1 should be Card or Group", 2)
	end
	if aux.GetValueType(hp) ~= "number" then
		error("parameter 2 should be number", 2)
	end
	if hp < 0 then
		error("parameter 2 should be >= 0", 2)
	end

	for c in aux.Next(g_c) do
		if not c:IsLocation(LOCATION_MZONE) then
			error("card must be in monster zone", 2)
		end

		local desired_hp = math.floor(hp)
		if desired_hp < 0 then desired_hp = 0 end

		local hp_system_found = false
		local effects = {c:IsHasEffect(EVENT_ADJUST)}
		for _, eff in ipairs(effects) do
			if eff:GetOperation() == Galaxy.CalculateHp then
				local hp_max_ori, hp_max_now = eff:GetLabel()
				if type(hp_max_now) == "number" and desired_hp > hp_max_now then
					desired_hp = hp_max_now
				end
				local hp_effect = eff:GetLabelObject()
				if hp_effect then
					hp_effect:SetValue(desired_hp)
				end
				hp_system_found = true
				break
			end
		end

		c:ResetFlagEffect(FLAG_SET_HP_PENDING)
		if not hp_system_found then
			c:RegisterFlagEffect(FLAG_SET_HP_PENDING, 0, EFFECT_FLAG_CANNOT_DISABLE, 1, desired_hp)
		end
		Duel.AdjustInstantly(c)
	end
end

---Galaxy HP事件触发函数（简化统一处理）
---@param c Card 怪兽卡
---@param hp_change number HP变化量（正数为恢复，负数为伤害）
---@param is_effect_change boolean 是否为EFFECT_UPDATE_HP变化
---@param reason integer 原因（REASON_BATTLE 或 REASON_EFFECT）
---@param effect_player integer 效果玩家
function Galaxy.RaiseHpEvent(c, hp_change, is_effect_change, reason, effect_player)
	if not c or not c:IsLocation(LOCATION_MZONE) or hp_change == 0 then return end

	-- 确定事件代码
	local event_code
	if is_effect_change then
		event_code = GALAXY_EVENT_HP_EFFECT_CHANGE
	elseif hp_change > 0 then
		event_code = GALAXY_EVENT_HP_RECOVER
	else
		event_code = GALAXY_EVENT_HP_DAMAGE
	end

	-- 立即触发事件（同时兼容场地与单体监听）
	local event_value = math.abs(hp_change)
	local reason_flag = reason or REASON_EFFECT
	local event_player = c:GetControler()
	local responsible_player = event_player

	-- 战斗伤害：责任玩家取攻击方控制者
	if reason_flag & REASON_BATTLE ~= 0 then
		local atker = Duel.GetAttacker()
		if atker then responsible_player = atker:GetControler() end
	else
		-- 若指定了 effect_player，则用该玩家作为责任方
		if effect_player ~= nil then responsible_player = effect_player end
	end

	local group = Group.FromCards(c)
	-- 场效果/全局监听
	Duel.RaiseEvent(group, event_code, nil, reason_flag, responsible_player, event_player, event_value)
	-- 单体效果监听（如 EFFECT_TYPE_SINGLE 触发）
	Duel.RaiseSingleEvent(c, event_code, nil, reason_flag, responsible_player, event_player, event_value)

	-- 调整以确保 HP 变化即时生效
	Duel.AdjustInstantly(c)
end

--[[
--==============================================
-- 暂时无用
--==============================================

--补给代价系统配置
Galaxy.USE_COST_SYSTEM = true
--Galaxy.SPELL_TRAP_COST = true   --魔法陷阱发动需要代价（暂时禁用）
Galaxy.SPELL_TRAP_COST = false  --魔法陷阱发动暂时不需要代价

--补给代价系统基础函数
Galaxy.DEFAULT_SUMMON_COST = 0   --怪兽召唤/特殊召唤默认代价（实际使用星级）
Galaxy.DEFAULT_ACTIVATE_COST = 0   --魔法/陷阱发动默认代价

--代价存储的Flag ID
Galaxy.SUMMON_COST_FLAG = 99990001  --召唤代价Flag
Galaxy.ACTIVATE_COST_FLAG = 99990002  --发动代价Flag

--获取卡片的召唤代价（从Flag读取，怪兽默认为星级）
function Galaxy.GetSummonCost(c)
	--检查卡片是否有自定义代价Flag
	if c:GetFlagEffect(Galaxy.SUMMON_COST_FLAG) > 0 then
		return c:GetFlagEffectLabel(Galaxy.SUMMON_COST_FLAG)
	end
	--怪兽卡默认代价为星级，其他卡片默认为0
	if c:IsType(TYPE_MONSTER) then
		return c:GetLevel()
	end
	return Galaxy.DEFAULT_SUMMON_COST
end

--获取卡片的发动代价（从Flag读取）
function Galaxy.GetActivateCost(c)
	--检查卡片是否有自定义代价Flag
	if c:GetFlagEffect(Galaxy.ACTIVATE_COST_FLAG) > 0 then
		return c:GetFlagEffectLabel(Galaxy.ACTIVATE_COST_FLAG)
	end
	--默认无代价
	return Galaxy.DEFAULT_ACTIVATE_COST
end

--为卡片设置召唤代价的便捷函数
function Galaxy.SetSummonCost(c, cost)
	--使用RegisterFlagEffect存储代价信息
	c:RegisterFlagEffect(Galaxy.SUMMON_COST_FLAG, 0, 0, 0, cost)
end

--为卡片设置发动代价的便捷函数
function Galaxy.SetActivateCost(c, cost)
	--使用RegisterFlagEffect存储代价信息
	c:RegisterFlagEffect(Galaxy.ACTIVATE_COST_FLAG, 0, 0, 0, cost)
end

--为魔法/陷阱卡添加发动代价效果（通用代价包装）
--注意：此功能已暂时禁用，魔法陷阱卡发动暂时不需要支付代价
function Galaxy.AddActivateCostToCard(c)
	if not Galaxy.USE_COST_SYSTEM or not Galaxy.SPELL_TRAP_COST then return end
	if not c or not (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) then return end

	--此函数现在主要用于标记卡片需要代价
	--实际代价处理通过Galaxy.WrapCost函数进行，在各卡片脚本中调用
	--使用方式: e1:SetCost(Galaxy.WrapCost(c, original_cost_function))
end

--通用的补给代价包装函数：将Galaxy补给代价与原始代价组合
function Galaxy.WrapCost(c, original_cost)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		local galaxy_cost = Galaxy.GetActivateCost and Galaxy.GetActivateCost(c) or 0

		if chk==0 then
			--检查Galaxy代价
			local galaxy_ok = true
			if galaxy_cost > 0 then
				galaxy_ok = Duel.CheckSupplyCost(tp, galaxy_cost) or false
			end
			--检查原始代价
			local original_ok = not original_cost or original_cost(e,tp,eg,ep,ev,re,r,rp,chk)
			return galaxy_ok and original_ok
		else
			--支付Galaxy代价
			if galaxy_cost > 0 then
				Duel.PaySupplyCost(tp, galaxy_cost)
			end
			--支付原始代价
			if original_cost then
				original_cost(e,tp,eg,ep,ev,re,r,rp,chk)
			end
		end
	end
end

--简化版本：无原始代价的包装函数
function Galaxy.SimpleCost(c)
	return Galaxy.WrapCost(c, nil)
end

--发动补给代价支付操作
function Galaxy.ActivateCostOperation(e,tp,eg,ep,ev,re,r,rp)
	local c = e:GetHandler()
	local cost = Galaxy.GetActivateCost(c)
	Duel.PaySupplyCost(tp, cost)
end
--]]
