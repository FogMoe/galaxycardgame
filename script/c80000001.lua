--肥硕工虫
--每当1个军团单位死亡，获得+1/+1。
--死亡时，使你的所有节肢类单位获得其剩余属性值。

local s,id = Import()
function s.initial(c)
	-- 效果1：每当1个军团单位死亡，获得+1/+1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCondition(s.atkcon)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	-- 效果2：死亡时，使你的所有节肢类单位获得其剩余属性值
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.deathcon)
	e2:SetOperation(s.deathop)
	c:RegisterEffect(e2)
end

-- 效果1的条件：有军团单位从场上去墓地
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.atkfilter,1,nil)
end

-- 筛选从场上去墓地的军团单位
function s.atkfilter(c)
	return c:IsGalaxyProperty(GALAXY_PROPERTY_LEGION)
		and c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

-- 效果2的条件：必须从场上去墓地
function s.deathcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

-- 效果1的操作：每个军团单位死亡都给+1/+1
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		-- 计算从场上去墓地的军团单位数量
		local ct=eg:FilterCount(s.atkfilter,nil)

		-- 获得+ct攻击力（永久加成）
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- 获得+ct最大HP（永久加成）
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_HP)
		e2:SetValue(ct)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end

-- 效果2：死亡时给所有节肢类单位加属性
function s.deathop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 获取这张卡死亡前的属性值（最后已知信息）
	local atk=c:GetPreviousAttackOnField()
	local hp=c:GetPreviousDefenseOnField()

	-- 获取我方所有节肢类单位
	local g=Duel.GetMatchingGroup(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
	if #g>0 then
		for tc in aux.Next(g) do
			-- 增加攻击力
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(atk)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)

			-- 只有当死亡时还有HP（hp>0）时才增加最大HP
			if hp>0 then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_UPDATE_HP)
				e2:SetValue(hp)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)
			end
		end
	end
end

-- 筛选节肢类单位
function s.filter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
end
