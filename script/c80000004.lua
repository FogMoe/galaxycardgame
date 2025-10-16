--信息素：出芽
--支援卡：消耗1点补给，对所有友方单位造成1点伤害，每造成1点伤害，制造并部署1个1/1的幼小爬虫。

local s,id=Import()

function s.initial(c)
	-- 激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗1点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,1) end
	Duel.PaySupplyCost(tp,1)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
	Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,g:GetCount(),0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 获取所有友方单位
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
	local max_targets=g:GetCount()
	if max_targets==0 then return end

	-- 对所有单位造成1点伤害
	Duel.AddHp(g,-1,REASON_EFFECT)

	-- 统计实际造成伤害的单位数量
	local damage_count=0
	for tc in aux.Next(g) do
		if tc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and tc:GetHp()>0 and not tc:IsHasEffect(EFFECT_SHIELD) then
			-- 有剩余HP且未持有护盾，视为受到伤害
			damage_count=damage_count+1
		elseif not tc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) then
			-- 已离场也算作受到伤害
			damage_count=damage_count+1
		end
	end

	-- 根据造成的伤害次数，制造对应数量的幼小爬虫
	if damage_count<=0 then return end
	damage_count=math.min(damage_count,max_targets)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<=0 then return end
	damage_count=math.min(damage_count,ft)
	if damage_count<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,80000003,0,TYPES_TOKEN_MONSTER,1,1,1,0,0) then return end

	for i=1,damage_count do
		local token=Duel.CreateToken(tp,80000003)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
	Duel.SpecialSummonComplete()
end
