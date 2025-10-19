--生命催化
--支援卡：卡组中只有植物类单位时，消耗3点补给，增加1点补给上限。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗3点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end

-- 激活条件：卡组中只有植物类单位
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- 获取卡组中所有单位卡
	local g=Duel.GetMatchingGroup(s.unitfilter,tp,LOCATION_DECK,0,nil)
	-- 如果没有单位卡，返回false
	if #g==0 then return false end
	-- 检查是否所有单位都是植物类
	return not g:IsExists(s.nonplantfilter,1,nil)
end

-- 筛选单位卡
function s.unitfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT)
end

-- 筛选非植物类单位
function s.nonplantfilter(c)
	return not c:IsRace(RACE_PLANT)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 增加1点补给上限（上限10）
	local max_supply=Duel.GetMaxSupply(tp)
	if max_supply<10 then
		Duel.AddMaxSupply(tp,1)
	end
	Duel.BreakEffect()
	Duel.SendtoGrave(e:GetHandler(),REASON_DISCARD)
end
