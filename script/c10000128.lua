--星墓死灵君主
--每当双方有单位死亡时，自己获得3点影响力。
--死亡时，制造1张残骸碎片，加入手牌。
local s, id = Import()
function s.initial(c)
	--双方单位死亡时获得影响力
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(GALAXY_LOCATION_UNIT_ZONE)
	e1:SetCondition(s.reccon)
	e1:SetOperation(s.recop)
	c:RegisterEffect(e1)

	--死亡时制造残骸碎片加入手牌
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--单位死亡过滤器（双方）
function s.deathfilter(c)
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsType(GALAXY_TYPE_UNIT)
end

--单位死亡条件
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.deathfilter,1,nil)
end

--获得影响力操作
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end

	--计算死亡的单位数量（双方）
	local ct=eg:FilterCount(s.deathfilter,nil)
	if ct>0 then
		--每个死亡单位恢复3点影响力
		Duel.Recover(tp,ct*3,REASON_EFFECT)
	end
end

--死亡条件：从场上进入墓地
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
end

--死亡目标
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

--死亡操作：制造残骸碎片加入手牌
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local token=Duel.CreateToken(tp,10000129)
	if token then
		Duel.SendtoHand(token,tp,REASON_EFFECT)
	end
end
