--墓宴领主
--部署时，选择1个友方单位，吸收其全部战斗力和生命值。
--每当有友方单位死亡时，获得+1战斗力。
local s, id = Import()
function s.initial(c)
	--部署时吸收友方单位属性
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetTarget(s.absorbtg)
	e1:SetOperation(s.absorbop)
	c:RegisterEffect(e1)

	--友方单位死亡时获得+1战斗力
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--友方单位过滤器
function s.filter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

--部署时吸收目标
function s.absorbtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and chkc:IsControler(tp) and s.filter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,1,e:GetHandler())
end

--部署时吸收操作
function s.absorbop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	--获取目标的攻击力和生命值
	local atk=tc:GetAttack()
	local hp=tc:GetHp()

	--墓宴领主获得目标的攻击力
	if atk>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end

	--墓宴领主获得目标的生命值
	if hp>0 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_HP)
		e2:SetValue(hp)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end

	--目标失去其全部攻击力
	if atk>0 then
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_UPDATE_ATTACK)
		e3:SetValue(-atk)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e3)
	end

	--目标失去其全部生命值（将其生命值归零）
	if hp>0 then
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_UPDATE_HP)
		e4:SetValue(-hp)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e4)
	end
end

--友方单位死亡过滤器
function s.deathfilter(c,tp)
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsPreviousControler(tp)
		and c:IsType(GALAXY_TYPE_UNIT)
end

--友方单位死亡条件
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.deathfilter,1,nil,tp)
end

--友方单位死亡时获得攻击力操作
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end

	--计算死亡的友方单位数量
	local ct=eg:FilterCount(s.deathfilter,nil,tp)
	if ct>0 then
		--每个死亡单位获得+1攻击力
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end
