--游牧母舰"自由号" 大型战舰
--部署时，部署2个临时的1/2的护卫无人机（10000076）。
--每回合自己补给阶段，可以消耗2点补给，部署1个临时的1/2的护卫无人机（攻击时，对所有敌方单位造成1点伤害）。
local s, id = Import()
function s.initial(c)
	--免疫1次战斗伤害（护盾效果）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e1)
	--部署时特殊召唤护卫无人机
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--每回合补给阶段可选效果：消耗2点补给部署1个护卫无人机
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+GALAXY_PHASE_SUPPLY)
	e3:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.spcon2)
	e3:SetCost(s.spcost2)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end

--特殊召唤目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=2
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000076,0,TYPES_TOKEN_MONSTER,1,2,1,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end

--特殊召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<2 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000076,0,TYPES_TOKEN_MONSTER,1,2,1,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) then return end

	for i=1,2 do
		local token=Duel.CreateToken(tp,10000076)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
	Duel.SpecialSummonComplete()
end

--补给阶段条件（自己的回合）
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

--补给阶段消耗2点补给
function s.spcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

--补给阶段特殊召唤目标
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000076,0,TYPES_TOKEN_MONSTER,1,2,1,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

--补给阶段特殊召唤操作
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<1 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000076,0,TYPES_TOKEN_MONSTER,1,2,1,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) then return end

	local token=Duel.CreateToken(tp,10000076)
	Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	Duel.SpecialSummonComplete()
end