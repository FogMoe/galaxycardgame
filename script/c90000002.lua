--阿尔提娅
--支援卡：自己场上没有植物类单位以外的单位时，每回合限1次，消耗2点补给，获得3点影响力。

local s,id=Import()

function s.initial(c)
	-- 激活效果：消耗2补给，获得3影响力
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(GALAXY_LOCATION_SUPPORT_ZONE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 检查场上是否只有植物类单位（或没有单位）
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- 自己场上不存在非植物类的单位
	return not Duel.IsExistingMatchingCard(s.nonplantfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil)
end

-- 非植物类单位过滤器
function s.nonplantfilter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT) and not c:IsRace(RACE_PLANT)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,3)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	-- 获得3点影响力
	Duel.Recover(p,3,REASON_EFFECT)
end
