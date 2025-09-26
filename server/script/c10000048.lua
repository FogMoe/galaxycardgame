--巢穴卫士
--保护友军单位。
--死亡时，如果你控制其他节肢类单位，部署一个0/1的虫卵并使其获得效果（保护友方单位）。
local s, id = Import()
function s.initial(c)
	--保护效果
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PROTECT)
	c:RegisterEffect(e1)

	--死亡时触发效果
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

function s.filter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) and c:IsPreviousControler(tp)
		and Duel.IsExistingMatchingCard(s.filter,tp,GALAXY_LOCATION_UNIT_ZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000041,0,TYPES_TOKEN_MONSTER,0,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000041,0,TYPES_TOKEN_MONSTER,0,1,1,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) then return end

	local token=Duel.CreateToken(tp,10000041)
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		--保护效果
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_PROTECT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1,true)

		--显示保护效果提示
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e2,true)
	end
end