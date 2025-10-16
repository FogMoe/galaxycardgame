--星岩采集
local s,id=Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.con)
	e1:SetCost(s.cost)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
function s.con(e,tp)
	return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0) > Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end
function s.op(e,tp)
	if Duel.IsPlayerCanDraw(tp,2) then
		Duel.Draw(tp,2,REASON_EFFECT)
	end
end
