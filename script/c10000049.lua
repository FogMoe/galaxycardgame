--虚空利维坦
--在部署的回合就可以攻击。
--当你部署其他节肢类单位时，获得+1/+1。
local s, id = Import()
function s.initial(c)
	--冲锋能力
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_RUSH)
	c:RegisterEffect(e1)

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