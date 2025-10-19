--烈火焚原
--消耗3点补给，对场上的所有单位造成1点伤害。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 成本：消耗3点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end

-- 目标：检查是否有单位可以造成伤害
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
	end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,#g,0,0)
end

-- 操作：对场上所有单位造成1点伤害
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.AddHp(g,-1,REASON_EFFECT)
	end
	Duel.BreakEffect()
	Duel.SendtoGrave(e:GetHandler(),REASON_DISCARD)
end
