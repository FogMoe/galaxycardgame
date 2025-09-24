--地面发电机
local s, id = Import()
function s.initial(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--永续支援卡，1回合1次，自己战备阶段开始时必发，额外获得1点补给
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	--e2:SetCategory(CATEGORY_RECOVER)  --原版：回复影响力用
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_PHASE+PHASE_DRAW)
	e2:SetCountLimit(1)
	e2:SetCondition(s.reccon)
	e2:SetOperation(s.supop)  --新版：获得补给
	c:RegisterEffect(e2)
end

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end

function s.supop(e,tp,eg,ep,ev,re,r,rp)
	Duel.AddSupply(tp,1)  --新版：额外获得1点补给
end

--原版函数（注释保留）
--function s.recop(e,tp,eg,ep,ev,re,r,rp)
--	Duel.Recover(tp,2,REASON_EFFECT)  --原版：回复2点影响力
--end
