--孵化爆发（oldname:虫群增援)
--支援卡，消耗3点补给，部署两个临时的2/1的幼虫战士（衍生物编号为10000042）。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,3) end
	Duel.PaySupplyCost(tp,3)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=2
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000042,0,TYPES_TOKEN_MONSTER,2,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<2 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000042,0,TYPES_TOKEN_MONSTER,2,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) then return end

	for i=1,2 do
		local token=Duel.CreateToken(tp,10000042)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
	Duel.SpecialSummonComplete()
end
