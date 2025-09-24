--虫后意志
--效果1：部署时，部署三个1/1的临时的虫卵（衍生物编号为10000041）。当虫卵被破坏时，部署一个临时的2/1的幼虫战士（衍生物编号为10000042）。
--效果2：你的节肢类单位获得+0/+1。
local s, id = Import()
function s.initial(c)
	--部署时特殊召唤衍生物
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--节肢类单位攻击力和守备力提升
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e2:SetTargetRange(GALAXY_LOCATION_UNIT_ZONE,0)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetTarget(s.atktg)
	e2:SetValue(0)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(1)
	c:RegisterEffect(e3)

	--虫卵被破坏时召唤幼虫战士
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.eggcon)
	e4:SetTarget(s.eggtg)
	e4:SetOperation(s.eggop)
	c:RegisterEffect(e4)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>=3
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000041,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,3,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,3,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<3 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000041,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) then return end

	for i=1,3 do
		local token=Duel.CreateToken(tp,10000041)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
	Duel.SpecialSummonComplete()
end

function s.atktg(e,c)
	return c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.eggfilter(c,tp)
	return c:IsCode(10000041) and c:IsReason(REASON_DESTROY)
		and c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsPreviousPosition(POS_FACEUP)
		and c:IsPreviousControler(tp)
end

function s.eggcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.eggfilter,1,nil,tp)
end

function s.eggtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000042,0,TYPES_TOKEN_MONSTER,2,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) end
	local ct=eg:FilterCount(s.eggfilter,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,ct,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,ct,0,0)
end

function s.eggop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ct=eg:FilterCount(s.eggfilter,nil,tp)
	local ft=Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)
	if ft<=0 then return end
	if ct>ft then ct=ft end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000042,0,TYPES_TOKEN_MONSTER,2,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) then return end

	for i=1,ct do
		local token=Duel.CreateToken(tp,10000042)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
	end
	Duel.SpecialSummonComplete()
end
