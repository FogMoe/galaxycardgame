--造成战斗伤害后破坏目标单位。
local s, id = Import()
function s.initial(c)
	--造成战斗伤害后破坏目标单位
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(GALAXY_EVENT_HP_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

--检查是否是自己造成的战斗伤害
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_MZONE) then return false end

	--检查伤害是否由战斗造成且是自己造成的
	return r==REASON_BATTLE and re and re:GetHandler()==c and eg:GetFirst():IsLocation(LOCATION_MZONE)
end

--破坏目标
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local target=eg:GetFirst()
	if chk==0 then return target and target:IsDestructable() end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,target,1,0,0)
end

--执行破坏
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local target=eg:GetFirst()
	if target and target:IsLocation(LOCATION_MZONE) then
		--添加已使用效果的客户端提示
		c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))

		Duel.Destroy(target,REASON_EFFECT)
	end
end