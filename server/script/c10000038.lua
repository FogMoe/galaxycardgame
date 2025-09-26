--适应性战士
--当一个友方节肢类单位死亡时，获得+1战斗力。
local s, id = Import()
function s.initial(c)
	--友方节肢类单位死亡时攻击力上升
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCondition(s.atkcon)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
end

function s.filter(c,tp)
	return c:IsPreviousPosition(POS_FACEUP)
		and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD)
		and c:IsType(GALAXY_TYPE_UNIT)
		and c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsPreviousControler(tp)
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil,tp)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
		c:RegisterEffect(e1)
	end
end

