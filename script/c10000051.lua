--深渊孵化
--从特殊卡组部署1个节肢类大型舰队，消耗其需求的补给数量，如补给不足以消耗，则将那个单位效果无效变为0/1，下次自己回合的补给阶段时送往游戏外。
local s, id = Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.filter(c,e,tp)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
		and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if g:GetCount()==0 then return end

	local tc=g:GetFirst()
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		local cost=tc:GetLevel()
		if Duel.CheckSupplyCost(tp,cost) then
			--补给足够，支付代价
			Duel.PaySupplyCost(tp,cost)
		else
			--补给不足，将单位变为0/1，下次补给阶段送往游戏外
			--失去1影响力（失去1hp）
			--Duel.PayLPCost(tp,1)
			Duel.Damage(tp,1,REASON_EFFECT)
			--变为0/1
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK)
			e1:SetValue(0)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_DEFENSE)
			e2:SetValue(1)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)

			--下次自己补给阶段送往游戏外
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetDescription(aux.Stringid(id,0))
			e3:SetCategory(CATEGORY_REMOVE)
			e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
			e3:SetCode(EVENT_PHASE+PHASE_DRAW)
			e3:SetRange(GALAXY_LOCATION_UNIT_ZONE)
			e3:SetCountLimit(1)
			e3:SetCondition(s.rmcon)
			e3:SetOperation(s.rmop)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DRAW+RESET_SELF_TURN,1)
			tc:RegisterEffect(e3)
			--效果无效
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_DISABLE)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e4)
			local e5=e4:Clone()
			e5:SetCode(EFFECT_DISABLE_EFFECT)
			e5:SetValue(RESET_TURN_SET)
			tc:RegisterEffect(e5)
			--不能攻击
			local e6=Effect.CreateEffect(e:GetHandler())
			e6:SetType(EFFECT_TYPE_SINGLE)
			e6:SetCode(EFFECT_CANNOT_ATTACK)
			e6:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e6)
		end
	end
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	end
end