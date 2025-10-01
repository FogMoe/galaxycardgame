--光合作用脉冲
--消耗3点补给，为所有友方单位回复2点生命值，若目标为植物类单位，改为回复4点。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--补给成本
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end

--友方单位过滤器
function s.filter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

--目标检查
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
	if g:GetCount()==0 then return end

	local tc=g:GetFirst()
	while tc do
		--判断是否为植物类单位
		local heal_amount = 2
		if tc:IsRace(RACE_PLANT) then
			heal_amount = 4
		end

		--回复生命值
		Duel.AddHp(tc, heal_amount, REASON_EFFECT)

		tc=g:GetNext()
	end
end
