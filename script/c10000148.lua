--人类反叛军团
--部署时，从卡组抽1张除人类以外的单位卡。

local s,id=Import()

function s.initial(c)
	-- 部署时，从卡组随机抽取1张非人类类单位卡
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

-- 筛选非人类类单位卡
function s.filter(c)
	return c:IsType(GALAXY_TYPE_UNIT)
		and not c:IsGalaxyCategory(GALAXY_CATEGORY_HUMAN)
		and c:IsAbleToHand()
end

-- 检索目标
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- 随机抽取操作
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		local tc=g:RandomSelect(tp,1):GetFirst()
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND) or c:IsPreviousLocation(LOCATION_EXTRA)
end
