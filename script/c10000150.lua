--星际同盟协定
--支援卡：卡组中同时有人类、机械类和节肢类单位时，消耗3点补给，增加1点补给上限。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
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

-- 激活条件：卡组中同时有人类、机械类、节肢类单位
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local has_human=Duel.IsExistingMatchingCard(s.humanfilter,tp,LOCATION_DECK,0,1,nil)
	local has_machine=Duel.IsExistingMatchingCard(s.machinefilter,tp,LOCATION_DECK,0,1,nil)
	local has_arthropod=Duel.IsExistingMatchingCard(s.arthropodfilter,tp,LOCATION_DECK,0,1,nil)
	return has_human and has_machine and has_arthropod
end

-- 筛选人类单位
function s.humanfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT) and c:IsGalaxyCategory(GALAXY_CATEGORY_HUMAN)
end

-- 筛选机械类单位
function s.machinefilter(c)
	return c:IsType(GALAXY_TYPE_UNIT) and c:IsRace(RACE_MACHINE)
end

-- 筛选节肢类单位
function s.arthropodfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT) and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 增加1点补给上限（上限10）
	local max_supply=Duel.GetMaxSupply(tp)
	if max_supply<10 then
		Duel.AddMaxSupply(tp,1)
	end
end
