--泽尔矩阵
--支援卡：每回合限1次，自己场上有机械类单位时，消耗2点补给，制造1张10000164加入手卡。

local s,id=Import()

function s.initial(c)
	-- 激活效果：消耗2补给，制造10000164加入手卡
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
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

-- 自己场上有机械类单位
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.machinefilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil)
end

-- 筛选机械类单位
function s.machinefilter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 制造1张10000164
	local token=Duel.CreateToken(tp,10000164)
	if token then
		-- 加入手卡
		Duel.SendtoHand(token,nil,REASON_EFFECT)
	end
end
