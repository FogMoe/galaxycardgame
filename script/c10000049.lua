--虚空利维坦
--自己场上只有节肢类单位才能部署。
--在部署的回合就可以直接攻击。
--当你部署节肢类单位时，获得+1/+1。
local s, id = Import()
function s.initial(c)
	--召唤限制：场上只有节肢类单位才能部署
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--冲锋能力
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_RUSH)
	c:RegisterEffect(e2)

	--节肢类单位部署时获得+1/+1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e3:SetCondition(s.atkcon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

--召唤限制条件：场上只有节肢类单位（且至少1个）
function s.spcon(e)
	local tp = e:GetHandlerPlayer()
	local g = Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
	-- 场上没有单位时不能部署
	if g:GetCount() == 0 then return false end
	-- 必须至少有1个节肢类单位，且不能有非节肢类单位
	return g:IsExists(s.arthropodfilter,1,nil) and not g:IsExists(s.notarthropodfilter,1,nil)
end

--过滤节肢类单位
function s.arthropodfilter(c)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
end

--过滤非节肢类单位
function s.notarthropodfilter(c)
	return not c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
end

function s.filter(c,tp)
	return c:IsControler(tp) and c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
		and c:IsType(GALAXY_TYPE_UNIT)
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsExists(s.filter,1,c,tp)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local ct=eg:FilterCount(s.filter,c,tp)
		if ct>0 then
			--获得+1/+1
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(ct)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
			c:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_HP)
			c:RegisterEffect(e2)
		end
	end
end