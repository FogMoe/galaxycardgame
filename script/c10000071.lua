--反重力机甲骑兵
local s, id = Import()
function s.initial(c)
	--攻击时，抽1张卡
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetTarget(s.drawtg)
	e1:SetOperation(s.drawop)
	c:RegisterEffect(e1)
	--战斗后，获得+2生命值（防御力）
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_DAMAGE_STEP_END)
	e2:SetCondition(s.defcon)
	e2:SetOperation(s.defop)
	c:RegisterEffect(e2)
end

--抽卡目标
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

--抽卡操作
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end

--防御力增加条件（战斗后没死）
function s.defcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (c==Duel.GetAttacker() or c==Duel.GetAttackTarget()) and c:IsRelateToBattle() and c:IsLocation(LOCATION_MZONE) and c:IsFaceup() and c:GetHp()>0
end

--防御力增加操作
function s.defop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_DEFENSE)
		e1:SetValue(2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end