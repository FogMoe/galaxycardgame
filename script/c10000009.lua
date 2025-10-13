--运送物资
local s, id = Import()
function s.initial(c)
	--回复2补给
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	--e1:SetCategory(CATEGORY_RECOVER)  --原版：回复影响力用
	--e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)  --原版：回复影响力用
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.suptg)
	e1:SetOperation(s.supop)
	c:RegisterEffect(e1)
end
function s.suptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	--Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,5)  --原版：回复影响力用
end
function s.supop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.AddSupply(p,d)  --新版：回复能源
	--Duel.Recover(p,d,REASON_EFFECT)  --原版：回复影响力

	-- 下次自己的补给阶段减少1补给
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PHASE+GALAXY_PHASE_SUPPLY)
	e2:SetCountLimit(1)
	e2:SetCondition(s.penaltycon)
	e2:SetOperation(s.penaltyop)
	e2:SetReset(RESET_PHASE+GALAXY_PHASE_SUPPLY+RESET_SELF_TURN)
	Duel.RegisterEffect(e2,tp)
end

-- 下次补给阶段的条件：自己的回合且是补给阶段
function s.penaltycon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.GetCurrentPhase()==GALAXY_PHASE_SUPPLY
end

-- 减少1补给
function s.penaltyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.AddSupply(tp,-1)
end