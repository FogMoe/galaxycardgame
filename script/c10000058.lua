--虚无缥缈的谜之军团
--单位卡。1保护友方单位。2被破坏时部署一个临时的1/1的逝而再现的影子军团10000059。3这张卡在场上可以被视为任意类别。
local s, id = Import()
function s.initial(c)
	--保护效果
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	--被破坏时部署影子军团
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--在场上可以被视为指定类别
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_ADD_RACE)
	e4:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e4:SetValue(GALAXY_CATEGORY_HUMAN+GALAXY_CATEGORY_MAMMAL+GALAXY_CATEGORY_REPTILE+GALAXY_CATEGORY_AVIAN+GALAXY_CATEGORY_ARTHROPOD+GALAXY_CATEGORY_MOLLUSK+GALAXY_CATEGORY_FUNGAL+GALAXY_CATEGORY_UNDEAD) -- 种族
	c:RegisterEffect(e4)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) and c:IsPreviousControler(tp)
		and c:IsReason(REASON_DESTROY)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_UNDEAD,GALAXY_PROPERTY_COMMANDER) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,id+1,0,TYPES_TOKEN_MONSTER,1,1,1,GALAXY_CATEGORY_UNDEAD,GALAXY_PROPERTY_COMMANDER) then return end

	local token=Duel.CreateToken(tp,id+1)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
end