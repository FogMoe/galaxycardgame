--柔星核
local s,id=Import()
function s.initial(c)
	-- 保护
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)
	-- 部署时选择造成伤害或摧毁影响力
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DAMAGE+CATEGORY_DEFCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetTarget(s.acttg)
	e2:SetOperation(s.actop)
	c:RegisterEffect(e2)
	-- 死亡时以1HP复活一次
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.revcon)
	e3:SetTarget(s.revtg)
	e3:SetOperation(s.revop)
	c:RegisterEffect(e3)
	-- 死亡时提高补给上限
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,5))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCondition(s.supcon)
	e4:SetOperation(s.supop)
	c:RegisterEffect(e4)
end
function s.dmgfilter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT) and c:GetHp()>0
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return e:GetLabel()==0 and chkc:IsControler(1-tp) and chkc:IsLocation(GALAXY_LOCATION_UNIT_ZONE) and s.dmgfilter(chkc) end
	local b1=Duel.IsExistingTarget(s.dmgfilter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,nil)
	local b2=true
	if chk==0 then return b1 or b2 end
	local option
	if b1 and b2 then
		option=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
	elseif b1 then
		Duel.SelectOption(tp,aux.Stringid(id,2))
		option=0
	else
		Duel.SelectOption(tp,aux.Stringid(id,3))
		option=1
	end
	e:SetLabel(option)
	if option==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DAMAGE)
		local g=Duel.SelectTarget(tp,s.dmgfilter,tp,0,GALAXY_LOCATION_UNIT_ZONE,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_DEFCHANGE,g,1,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1)
	end
end
function s.supcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) and Duel.GetMaxSupply(tp)>=10
end
function s.supop(e,tp,eg,ep,ev,re,r,rp)
	Duel.AddMaxSupply(tp,1)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local option=e:GetLabel()
	if option==0 then
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.AddHp(tc,-1,REASON_EFFECT)
		end
	else
		Duel.Damage(1-tp,1,REASON_EFFECT)
	end
end
function s.revcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) and c:IsPreviousControler(tp) and c:GetFlagEffect(id)==0
end
function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		Duel.SetHp(c,1)
		c:RegisterFlagEffect(id,0,EFFECT_FLAG_CANNOT_DISABLE,1)
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,4))
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		c:RegisterEffect(e2)
	end
end
