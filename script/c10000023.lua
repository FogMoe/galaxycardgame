--轨道轰炸
local s, id = Import()
function s.initial(c)
	--魔法卡，自己场上有大型单位（融合怪）时才能使用，减少对方全部怪兽1点def，那之后，可以再消耗3点补给，再减少对方全部怪兽1点def。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	e1:SetCondition(s.condition)
	c:RegisterEffect(e1)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,g:GetCount(),0,-1)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		Duel.AddHp(tc, -1, REASON_EFFECT)
	end
	--那之后，可以再消耗3点补给，再减少对方全部怪兽1点def
	if Duel.CheckSupplyCost(tp,3) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.BreakEffect()
		Duel.PaySupplyCost(tp,3)
		local g2=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		for tc in aux.Next(g2) do
			Duel.AddHp(tc, -1, REASON_EFFECT)
		end
	end
end
function s.cfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
