--放射性荆棘
local s,id=Import()
function s.initial(c)
	-- 护盾
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SHIELD)
	c:RegisterEffect(e1)
	-- 死亡时效果
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spmcon)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- 筛选器：非植物类的单位（这种单位会阻止效果发动）
function s.nonplantunitfilter(c)
	return c:IsType(GALAXY_TYPE_UNIT) and not c:IsRace(RACE_PLANT)
end

function s.spmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 检查1：必须从单位区进入墓地
	if not c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) then return false end
	-- 检查2：手牌中不能存在非植物类的单位（支援卡/战术卡不影响）
	local hand=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	return not hand:IsExists(s.nonplantunitfilter,1,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetMaxSupply(tp)>=10 then return end
	Duel.AddMaxSupply(tp,1)
end
