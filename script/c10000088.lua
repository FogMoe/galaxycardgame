--孢子菌毯网络 区域支援：回合结束时，消耗1点补给给双方部署1个临时的1/1的孢子体10000089。
--双方场上的真菌类获得+1生命值。
--双方场上的节肢类获得+1战斗力。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--回合结束时消耗1点补给给双方部署孢子体
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--双方场上的真菌类获得+1生命值
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_HP)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.fungaltg)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--双方场上的节肢类获得+1战斗力
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e3:SetTarget(s.arthropodtg)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

--孢子体召唤成本
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,1) end
	Duel.PaySupplyCost(tp,1)
end

--孢子体召唤目标
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,59822133)
		and not Duel.IsPlayerAffectedByEffect(1-tp,59822133)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_FUNGAL,0)
		and Duel.IsPlayerCanSpecialSummonMonster(1-tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_FUNGAL,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end

--孢子体召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end

	--给玩家tp部署孢子体
	if not Duel.IsPlayerAffectedByEffect(tp,59822133)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_FUNGAL,0) then
		local token1=Duel.CreateToken(tp,10000089)
		Duel.SpecialSummonStep(token1,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end

	--给对手部署孢子体
	if not Duel.IsPlayerAffectedByEffect(1-tp,59822133)
		and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(1-tp,10000089,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_FUNGAL,0) then
		local token2=Duel.CreateToken(1-tp,10000089)
		Duel.SpecialSummonStep(token2,0,1-tp,1-tp,false,false,POS_FACEUP_ATTACK)
	end

	Duel.SpecialSummonComplete()
end

--真菌类目标过滤器
function s.fungaltg(e,c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_FUNGAL) and c:IsType(GALAXY_TYPE_UNIT)
end

--节肢类目标过滤器
function s.arthropodtg(e,c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end