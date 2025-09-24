--战术投送舱 战术卡 消耗4点补给，部署1个临时的3/4的重装机甲兵10000078。如果你的影响力高于对手，使其获得（保护友方单位）和（免疫1次战斗伤害）。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--消耗4点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,4) end
	Duel.PaySupplyCost(tp,4)
end

--特殊召唤目标
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,59822133)
		and Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=1
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000078,0,TYPES_TOKEN_MONSTER,3,4,1,0,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

--激活操作
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) then return end
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<1 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000078,0,TYPES_TOKEN_MONSTER,3,4,1,0,0) then return end

	--部署重装机甲兵
	local token=Duel.CreateToken(tp,10000078)
	if Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK) then
		Duel.SpecialSummonComplete()

		--如果影响力高于对手，给重装机甲兵额外效果
		if Duel.GetLP(tp) > Duel.GetLP(1-tp) then
			--保护友方单位
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_PROTECT)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1,true)
			--免疫1次战斗伤害（护盾效果）
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SHIELD)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e2,true)

			--显示保护效果提示
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetDescription(aux.Stringid(id,1))
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e3:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e3,true)
			--显示护盾效果提示
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetDescription(aux.Stringid(id,2))
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
			e4:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			e4:SetCode(EFFECT_SHIELD_HINT) --护盾显示标识码
			token:RegisterEffect(e4,true)

		end
	end
end
