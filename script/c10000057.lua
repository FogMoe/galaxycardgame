--小型护卫舰
--临时单位。每自己回合补给阶段，消耗2点补给，如果无法支付则这张卡被破坏。
local s, id = Import()
function s.initial(c)
	--每自己回合补给阶段消耗2点补给
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_DRAW)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCondition(s.condition)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--检查补给是否足够支付2点代价
	if not Duel.CheckSupplyCost(tp,2) then
		--补给不足，破坏这张卡
		if c:IsFaceup() and c:IsRelateToEffect(e) then
			Duel.Destroy(c,REASON_EFFECT)
		end
		return
	end
	--支付2点补给代价
	Duel.PaySupplyCost(tp,2)
end