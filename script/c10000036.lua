--雷神炮艇
local s, id = Import()
function s.initial(c)
	--每自己回合抽卡阶段发动，消耗5补给，atk+1，如果无法支付补给代价则这张卡破坏。
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_DRAW)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--检查补给是否足够支付5点代价
	if not Duel.CheckSupplyCost(tp,5) then
		--补给不足，破坏这张卡
		if c:IsFaceup() and c:IsRelateToEffect(e) then
			Duel.Destroy(c,REASON_EFFECT)
		end
		return
	end
	--支付5点补给代价
	Duel.PaySupplyCost(tp,5)
	--攻击力+1
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
