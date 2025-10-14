--繁星花皇
--单位：自己影响力小于对手时此卡不能攻击。
--每次自己补给阶段，如果自己的影响力小于对手而且有补给，消耗全部补给，增加等值的影响力。

local s,id=Import()

function s.initial(c)
	-- 效果1：自己影响力小于对手时此卡不能攻击
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetCondition(s.atkcon)
	c:RegisterEffect(e1)

	-- 效果2：每次自己补给阶段，如果自己的影响力小于对手而且有补给，消耗全部补给，增加等值的影响力
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+GALAXY_PHASE_SUPPLY)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.reccon)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

-- 效果1的条件：自己影响力小于对手
function s.atkcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.GetLP(tp)<Duel.GetLP(1-tp)
end

-- 效果2的条件：自己回合 且 影响力小于对手 且 有补给
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
		and Duel.GetLP(tp)<Duel.GetLP(1-tp)
		and Duel.GetSupply(tp)>0
end

-- 效果2的操作：消耗全部补给，回复等量影响力
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local supply=Duel.GetSupply(tp)
	if supply>0 then
		-- 消耗全部补给
		Duel.PaySupplyCost(tp,supply)
		-- 回复等量影响力
		Duel.Recover(tp,supply,REASON_EFFECT)
	end
end
