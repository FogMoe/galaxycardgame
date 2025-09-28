--受到伤害后如果还存活获得潜行效果
local s, id = Import()
function s.initial(c)
	--受到伤害后获得潜行效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(GALAXY_EVENT_HP_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetCountLimit(1)
	e1:SetCondition(s.stealthcon)
	e1:SetOperation(s.stealthop)
	c:RegisterEffect(e1)
end

--检查是否还存活且未拥有潜行效果
function s.stealthcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_MZONE) and c:GetHp()>0 and not c:IsHasEffect(EFFECT_STEALTH)
end

--获得潜行效果
function s.stealthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsLocation(LOCATION_MZONE) then return end

	--添加已使用效果的客户端提示
	c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))

	--潜行效果：不能成为攻击和效果的对象，攻击后移除
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_STEALTH)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)

	--立即添加潜行显示（手动调用显示函数）
	if not c:IsHasEffect(EFFECT_STEALTH_HINT) then
		local e2 = Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(10000077,3)) --潜行显示提示文本
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_STEALTH_HINT) --潜行显示标识码
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CLIENT_HINT)
		e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e2:SetReset(RESET_EVENT + RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end