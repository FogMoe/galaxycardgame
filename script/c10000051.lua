--深渊孵化
--从特殊卡组部署1个节肢类软体类大型舰队，消耗其需求的补给数量，如补给不足以消耗，则将那个单位效果无效变为0/1，下次自己回合的补给阶段时送往游戏外。
local s, id = Import()
function s.initial(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.filter(c,e,tp)
	return (c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) or c:IsGalaxyCategory(GALAXY_CATEGORY_MOLLUSK)) and c:IsType(GALAXY_TYPE_UNIT)
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

			-- 使用 EFFECT_UPDATE_HP 将最大HP降为1（当前HP会自动钳制）
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_UPDATE_HP)
			e2:SetValue(1 - tc:GetBaseHp())
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)

			--下次自己补给阶段送往游戏外
			local fid=tc:GetFieldID()
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,fid)
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetDescription(aux.Stringid(id,0))
			e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
			e3:SetCode(EVENT_PHASE+GALAXY_PHASE_SUPPLY)
			e3:SetCountLimit(1)
			e3:SetLabel(fid,Duel.GetTurnCount())
			e3:SetLabelObject(tc)
			e3:SetCondition(s.rmcon)
			e3:SetOperation(s.rmop)
			e3:SetReset(RESET_PHASE+GALAXY_PHASE_SUPPLY+RESET_SELF_TURN,2)
			Duel.RegisterEffect(e3,tp)
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
	Duel.BreakEffect()
	Duel.SendtoGrave(e:GetHandler(),REASON_DISCARD)
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local fid,ct=e:GetLabel()
	local tc=e:GetLabelObject()
	return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()~=ct and tc:GetFlagEffectLabel(id)==fid
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
end