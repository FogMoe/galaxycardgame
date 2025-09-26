--支援卡：消耗2点补给，部署两个临时的1/1的克隆体战士10000073。如果你其他控制哺乳类单位，它们获得+1/+1。
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
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,59822133)
		and Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=2
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000073,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_MAMMAL,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) then return end
	local ct=math.min(2,Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE))
	if ct>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,10000073,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_MAMMAL,0) then
		for i=1,ct do
			local token=Duel.CreateToken(tp,10000073)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
		end
		Duel.SpecialSummonComplete()

		--如果控制其他哺乳类单位，给克隆体战士+1/+1
		local mammal_count=Duel.GetMatchingGroupCount(s.mammalfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
		if mammal_count>0 then
			local tokens=Duel.GetMatchingGroup(s.tokenfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
			local tc=tokens:GetFirst()
			while tc do
				--攻击力+1
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(1)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				--防御力+1
				local e2=e1:Clone()
				e2:SetCode(EFFECT_UPDATE_DEFENSE)
				tc:RegisterEffect(e2)
				tc=tokens:GetNext()
			end
		end
	end
end

--哺乳类单位过滤器（排除克隆体战士本身）
function s.mammalfilter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_MAMMAL) and c:IsType(GALAXY_TYPE_UNIT) and not c:IsCode(10000073)
end

--刚召唤的克隆体战士过滤器
function s.tokenfilter(c)
	return c:IsFaceup() and c:IsCode(10000073)
end
