--星际联邦舰队
--支援卡，消耗6点补给，部署三个临时的小型护卫舰(衍生物10000057）。如果你的影响力高于对手，随机对一个敌方单位造成3点伤害。
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
	if chk==0 then return Duel.CheckSupplyCost(tp,6) end
	Duel.PaySupplyCost(tp,6)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,59822133)
		and Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=3
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000057,0,TYPES_TOKEN_MONSTER,2,2,2,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,3,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,3,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) then return end
	local ct=math.min(3,Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE))
	if ct>0 and Duel.IsPlayerCanSpecialSummonMonster(tp,10000057,0,TYPES_TOKEN_MONSTER,2,2,2,GALAXY_CATEGORY_MAMMAL,GALAXY_PROPERTY_FLEET) then
		for i=1,ct do
			local token=Duel.CreateToken(tp,10000057)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
		end
		Duel.SpecialSummonComplete()

		--如果影响力高于对手，随机对敌方单位造成伤害
		if Duel.GetLP(tp) > Duel.GetLP(1-tp) then
			local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
			if g:GetCount()>0 then
				local tc=g:RandomSelect(tp,1):GetFirst()
				if tc then
					--对选中的敌方单位造成3点伤害（减少3点防御力）
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_UPDATE_DEFENSE)
					e1:SetValue(-3)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1)
				end
			end
		end
	end
end