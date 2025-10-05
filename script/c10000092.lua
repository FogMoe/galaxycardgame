--战斗后破坏目标单位。
local s, id = Import()
function s.initial(c)
	--战斗后破坏目标单位
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_DAMAGE_STEP_END)
	e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

--破坏目标
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local bc=Duel.GetAttackTarget()
		-- 如果没有攻击目标（直接攻击玩家），则不触发效果
		if not bc then return false end
		-- 如果攻击目标是自己，则获取攻击者作为目标
		if bc==c then bc=Duel.GetAttacker() end
		return bc and bc:IsLocation(LOCATION_MZONE) and bc:IsDestructable()
	end
	local c=e:GetHandler()
	local bc=Duel.GetAttackTarget()
	if bc==c then bc=Duel.GetAttacker() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
end

--执行破坏
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local bc=Duel.GetAttackTarget()
	-- 如果没有攻击目标（直接攻击玩家），则不执行
	if not bc then return end
	-- 如果攻击目标是自己，则获取攻击者作为目标
	if bc==c then bc=Duel.GetAttacker() end
	if bc and bc:IsLocation(LOCATION_MZONE) and bc:IsDestructable() then
		c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
		Duel.Destroy(bc,REASON_EFFECT)
	end
end