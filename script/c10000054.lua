--生物质回收网络
--设施支援卡。当一个单位死亡时，获得1点生物质计数标记。你可以消耗1点补给和4点生物质计数标记来部署一个临时的2/2的适应虫(c10000055)。如果你控制3个以上节肢类单位，适应虫额外获得+1/+1。
local s, id = Import()
function s.initial(c)
	--启用计数器
	c:EnableCounterPermit(0x1041) --生物质计数器
	--激活
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	--单位死亡时增加计数器
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.ctcon)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)

	--消耗补给和计数器召唤适应虫
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--计数器相关
function s.ctfilter(c)
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE) and c:IsPreviousPosition(POS_FACEUP)
		and c:IsType(GALAXY_TYPE_UNIT)
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.ctfilter,nil)
	if ct>0 then
		e:GetHandler():AddCounter(0x1041,ct,true)
	end
end

--召唤效果相关
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckSupplyCost(tp,1) and e:GetHandler():GetCounter(0x1041)>=4
	end
	Duel.PaySupplyCost(tp,1)
	e:GetHandler():RemoveCounter(tp,0x1041,4,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,10000055,0,TYPES_TOKEN_MONSTER,2,2,2,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end

function s.arthropodfilter(c)
	return c:IsFaceup() and c:IsGalaxyCategory(GALAXY_CATEGORY_ARTHROPOD) and c:IsType(GALAXY_TYPE_UNIT)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,GALAXY_LOCATION_UNIT_ZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,10000055,0,TYPES_TOKEN_MONSTER,2,2,2,GALAXY_CATEGORY_ARTHROPOD,GALAXY_PROPERTY_LEGION) then return end

	local token=Duel.CreateToken(tp,10000055)
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)>0 then
		--检查是否控制3个以上节肢类单位（包括刚召唤的）
		local arthropod_count=Duel.GetMatchingGroupCount(s.arthropodfilter,tp,GALAXY_LOCATION_UNIT_ZONE,0,nil)
		if arthropod_count>=3 then
			--额外获得+1/+1
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1,true)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			token:RegisterEffect(e2,true)
		end
	end
end
