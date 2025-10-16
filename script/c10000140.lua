--火力打击
--支援卡：消耗4点补给，自己场上有机械类单位时可以使用，对全体敌方单位造成2点伤害。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗4点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,4) end
	Duel.PaySupplyCost(tp,4)
end

-- 自己场上有机械类单位
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil)
end

-- 筛选机械类单位
function s.filter(c)
	return c:IsFaceup() and c:IsRace(RACE_MACHINE) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,#g,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 获取所有敌方单位
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	if #g>0 then
		for tc in aux.Next(g) do
			-- 对每个敌方单位造成2点伤害
			Duel.AddHp(tc,-2,REASON_EFFECT)
		end
	end
end
