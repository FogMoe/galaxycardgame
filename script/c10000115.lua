--恒星藤蔓
--每当对方部署1个单位时，使其获得-1/-1。
local s, id = Import()
function s.initial(c)
	--监听对方部署单位
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCondition(s.debuffcon)
	e1:SetTarget(s.debufftg)
	e1:SetOperation(s.debuffop)
	c:RegisterEffect(e1)
end

--过滤对方新召唤的单位
function s.filter(c,tp)
	return c:IsControler(1-tp) and c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT)
end

--条件：对方部署了单位
function s.debuffcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil,tp)
end

--目标：对方新部署的所有单位
function s.debufftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.filter,1,nil,tp) end
	local g=eg:Filter(s.filter,nil,tp)
	Duel.SetTargetCard(g)
end

--操作：给对方新部署的单位添加-1/-1
function s.debuffop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	local g=Duel.GetTargetsRelateToChain():Filter(Card.IsFaceup,nil)
	local tc=g:GetFirst()
	while tc do
		--攻击力-1
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		--生命值-1
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_HP)
		tc:RegisterEffect(e2)
		tc=g:GetNext()
	end
end
