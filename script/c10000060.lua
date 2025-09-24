--不可辨识的"水母"触须
--保护友方单位。
--对方单位必须攻击。
--战斗时，对方玩家会受到攻击单位atk的伤害最多为这张卡的生命值。
local s, id = Import()
function s.initial(c)
	-- 保护效果：对方单位必须优先攻击这张卡
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	-- 强制攻击效果：对方单位必须攻击
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_MUST_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,0))
	c:RegisterEffect(e2)

	-- 战斗伤害反弹效果：战斗时对方玩家也受到相同伤害
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetCondition(s.damcon)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

-- 战斗伤害反弹条件：这张卡参与战斗且受到伤害
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and c:IsRelateToBattle() and bc:IsRelateToBattle()
end

-- 战斗伤害反弹操作：计算对方玩家受到的伤害
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc then return end

	-- 计算伤害：攻击单位ATK，但最多为这张卡的生命值
	local attack_damage = bc:GetAttack()
	local max_damage = c:GetDefense()
	local damage = math.min(attack_damage, max_damage)

	if damage > 0 then
		-- 对攻击方玩家造成伤害
		Duel.Damage(1-tp, damage, REASON_EFFECT)
	end
end