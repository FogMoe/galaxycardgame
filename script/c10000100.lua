--轨道守卫
--交战阶段开始时，对1个随机敌方单位造成 1-3 点伤害。然后这张卡随机获得没有的效果（护盾/保护/致命/潜行/被无效）其中任意一个。
local s, id = Import()
function s.initial(c)
	--交战阶段开始时，对1个随机敌方单位造成1-3点伤害，然后随机获得特殊效果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--第一部分：对随机敌方单位造成伤害
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,GALAXY_LOCATION_UNIT_ZONE,nil)
	if g:GetCount()>0 then
		local tc=g:RandomSelect(tp,1):GetFirst()
		if tc then
			--随机造成1-3点伤害
			local damage = math.random(1,3)
			Duel.AddHp(tc, -damage, REASON_EFFECT)
		end
	end

	--第二部分：随机获得没有的特殊效果
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		s.add_random_effect(c)
	end
end

--检查并添加随机特殊效果
function s.add_random_effect(c)
	local tp = c:GetControler()

	--定义可能的效果列表
	local available_effects = {}

	--检查护盾效果
	if not c:IsHasEffect(EFFECT_SHIELD) then
		table.insert(available_effects, {code = EFFECT_SHIELD, name = "护盾"})
	end

	--检查保护效果
	if not c:IsHasEffect(EFFECT_PROTECT) then
		table.insert(available_effects, {code = EFFECT_PROTECT, name = "保护"})
	end

	--检查致命效果
	if not c:IsHasEffect(EFFECT_LETHAL) then
		table.insert(available_effects, {code = EFFECT_LETHAL, name = "致命"})
	end

	--检查潜行效果
	if not c:IsHasEffect(EFFECT_STEALTH) then
		table.insert(available_effects, {code = EFFECT_STEALTH, name = "隐身"})
	end

	--检查是否无法使用效果
	if not c:IsHasEffect(EFFECT_CANNOT_TRIGGER) then
		table.insert(available_effects, {code = EFFECT_CANNOT_TRIGGER, name = "被无效"})
	end

	--检查额外攻击
	if not c:IsHasEffect(EFFECT_EXTRA_ATTACK_MONSTER) then
		table.insert(available_effects, {code = EFFECT_EXTRA_ATTACK_MONSTER, name = "连击"})
	end

	--检查是否无法攻击
	if not c:IsHasEffect(EFFECT_CANNOT_ATTACK) then
		table.insert(available_effects, {code = EFFECT_CANNOT_ATTACK, name = "不能攻击"})
	end

	--如果有可用效果，随机选择一个添加
	if #available_effects > 0 then
		local selected = available_effects[math.random(1, #available_effects)]

		--分别处理每种效果
		if selected.code == EFFECT_SHIELD then
			--护盾效果
			local e_shield=Effect.CreateEffect(c)
			e_shield:SetType(EFFECT_TYPE_SINGLE)
			e_shield:SetCode(EFFECT_SHIELD)
			e_shield:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_shield)
			--护盾客户端提示
			local e_shield_hint = Effect.CreateEffect(c)
			e_shield_hint:SetDescription(aux.Stringid(10000077,2))
			e_shield_hint:SetType(EFFECT_TYPE_SINGLE)
			e_shield_hint:SetCode(EFFECT_SHIELD_HINT)
			e_shield_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_shield_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_shield_hint)
		elseif selected.code == EFFECT_PROTECT then
			--保护效果
			local e_protect=Effect.CreateEffect(c)
			e_protect:SetType(EFFECT_TYPE_SINGLE)
			e_protect:SetCode(EFFECT_PROTECT)
			e_protect:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_protect)
			--保护客户端提示
			local e_protect_hint=Effect.CreateEffect(c)
			e_protect_hint:SetType(EFFECT_TYPE_SINGLE)
			e_protect_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_protect_hint:SetDescription(aux.Stringid(id, 2))
			e_protect_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_protect_hint)
		elseif selected.code == EFFECT_LETHAL then
			--致命效果
			local e_lethal=Effect.CreateEffect(c)
			e_lethal:SetType(EFFECT_TYPE_SINGLE)
			e_lethal:SetCode(EFFECT_LETHAL)
			e_lethal:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_lethal)
			--致命客户端提示
			local e_lethal_hint=Effect.CreateEffect(c)
			e_lethal_hint:SetType(EFFECT_TYPE_SINGLE)
			e_lethal_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_lethal_hint:SetDescription(aux.Stringid(id, 3))
			e_lethal_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_lethal_hint)
		elseif selected.code == EFFECT_STEALTH then
			--潜行效果
			local e_stealth=Effect.CreateEffect(c)
			e_stealth:SetType(EFFECT_TYPE_SINGLE)
			e_stealth:SetCode(EFFECT_STEALTH)
			e_stealth:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_stealth)
			--潜行客户端提示
			local e_stealth_hint = Effect.CreateEffect(c)
			e_stealth_hint:SetDescription(aux.Stringid(10000077,3))
			e_stealth_hint:SetType(EFFECT_TYPE_SINGLE)
			e_stealth_hint:SetCode(EFFECT_STEALTH_HINT)
			e_stealth_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_stealth_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_stealth_hint)
		elseif selected.code == EFFECT_EXTRA_ATTACK_MONSTER then
			--连击效果
			local e_extra_attack=Effect.CreateEffect(c)
			e_extra_attack:SetType(EFFECT_TYPE_SINGLE)
			e_extra_attack:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
			e_extra_attack:SetValue(1)
			e_extra_attack:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_extra_attack)
			--连击客户端提示
			local e_extra_attack_hint=Effect.CreateEffect(c)
			e_extra_attack_hint:SetType(EFFECT_TYPE_SINGLE)
			e_extra_attack_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_extra_attack_hint:SetDescription(aux.Stringid(id, 9))
			e_extra_attack_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_extra_attack_hint)
		elseif selected.code == EFFECT_CANNOT_TRIGGER then
			--不能使用效果
			local e_cannot_trigger=Effect.CreateEffect(c)
			e_cannot_trigger:SetType(EFFECT_TYPE_SINGLE)
			e_cannot_trigger:SetCode(EFFECT_CANNOT_TRIGGER)
			e_cannot_trigger:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_cannot_trigger)
			--提示
			local e_cannot_trigger_hint=Effect.CreateEffect(c)
			e_cannot_trigger_hint:SetType(EFFECT_TYPE_SINGLE)
			e_cannot_trigger_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_cannot_trigger_hint:SetDescription(aux.Stringid(id, 7))
			e_cannot_trigger_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_cannot_trigger_hint)
		elseif selected.code == EFFECT_CANNOT_ATTACK then
			--不能攻击
			local e_cannot_attack=Effect.CreateEffect(c)
			e_cannot_attack:SetType(EFFECT_TYPE_SINGLE)
			e_cannot_attack:SetCode(EFFECT_CANNOT_ATTACK)
			e_cannot_attack:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e_cannot_attack)
			--提示
			local e_cannot_attack_hint=Effect.CreateEffect(c)
			e_cannot_attack_hint:SetType(EFFECT_TYPE_SINGLE)
			e_cannot_attack_hint:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e_cannot_attack_hint:SetDescription(aux.Stringid(id, 8))
			e_cannot_attack_hint:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e_cannot_attack_hint)
		end
	end
end

