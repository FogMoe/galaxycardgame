--星陀罗
--大型舰队
local s,id=Import()
function s.initial(c)
	-- 仅允许通过自身条件特殊召唤
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetCondition(s.splimcon)
	c:RegisterEffect(e1)

	-- 自身部署条件：卡组仅包含植物类单位时可从额外卡组特殊召唤
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	e2:SetValue(SUMMON_VALUE_SELF)
	c:RegisterEffect(e2)

	-- 限制特殊召唤表示：只能以攻击表示进入场上
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_LIMIT_SPECIAL_SUMMON_POSITION)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_EXTRA)
	e3:SetTargetRange(1,0)
	e3:SetTarget(function(e,c,sump,sumtype,sumpos,targetp)
		return c==e:GetHandler() and bit.band(sumpos,POS_FACEUP_DEFENSE+POS_FACEDOWN_DEFENSE)~=0
	end)
	c:RegisterEffect(e3)

	-- 不能直接攻击
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
	c:RegisterEffect(e4)

	-- 战备阶段：减少补给上限并随机部署高补给单位，赋予闪击
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+GALAXY_PHASE_PREPARATION)
	e5:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e5:SetCondition(s.prepcon)
	e5:SetTarget(s.preptg)
	e5:SetOperation(s.prepop)
	c:RegisterEffect(e5)
end

-- 卡组单位过滤
function s.unitfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT)
end

function s.nonplantfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT) and not c:IsRace(RACE_PLANT)
end

-- 判断卡组是否只有植物类单位
function s.only_plant_units(tp)
	local g=Duel.GetMatchingGroup(s.unitfilter,tp,LOCATION_DECK,0,nil)
	if #g==0 then return false end
	return not g:IsExists(s.nonplantfilter,1,nil)
end

-- 特殊召唤限制检查
function s.splimcon(e)
	return s.only_plant_units(e:GetHandlerPlayer())
end

-- 自身部署条件与操作
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return s.only_plant_units(tp)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.CheckSupplyCost(tp,c:GetLevel())
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then return s.spcon(e,c) end
	e:SetLabel(c:GetLevel())
	return true
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local cost=e:GetLabel()
	if cost and cost>0 then
		local tp=c:GetControler()
		Duel.PaySupplyCost(tp,cost)
	end
end

-- 战备阶段发动条件
function s.prepcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetMaxSupply(tp)>=4
end

-- 查询随机补给>=5的单位ID
function s.get_random_high_supply_unit()
	local sql=string.format([[
		SELECT id FROM datas
		WHERE type & %d != 0
		AND type & %d = 0
		AND type & %d = 0
		AND level >= 5
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], TYPE_MONSTER, TYPE_TOKEN, TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
	local results=Duel.QueryDatabase(sql)
	if results and not results.error and #results>0 then
		return results[1].id
	end
	return nil
end

function s.preptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return false end
		local card_id=s.get_random_high_supply_unit()
		e:SetLabel(card_id or 0)
		return card_id~=nil
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.prepop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c or not c:IsRelateToEffect(e) then return end
	local tp=e:GetHandlerPlayer()
	if Duel.GetMaxSupply(tp)<3 then return end
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end
	local card_id=e:GetLabel()
	if card_id==0 then
		card_id=s.get_random_high_supply_unit()
		if not card_id then return end
	end
	Duel.AddMaxSupply(tp,-3)
	local token=Duel.CreateToken(tp,card_id)
	if not token then return end
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_RUSH_R)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1,true)

		local hint=Effect.CreateEffect(c)
		hint:SetDescription(aux.Stringid(id,2))
		hint:SetType(EFFECT_TYPE_SINGLE)
		hint:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		hint:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		hint:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(hint,true)
	end
	e:SetLabel(0)
end
