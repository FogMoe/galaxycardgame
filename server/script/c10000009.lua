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
end