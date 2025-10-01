--星核温室
--植物类单位部署时，获得+1/+1。
--植物类单位死亡时，给其控制者制造1张星核种子，加入其手卡。
local s, id = Import()
function s.initial(c)
	--激活效果
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--植物类单位部署时，获得+1/+1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCondition(s.atkcon)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	--植物类单位死亡时，给其控制者制造星核种子加入手牌
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--植物类单位过滤器（双方通用）
function s.filter(c)
	return c:IsFaceup() and c:IsRace(RACE_PLANT) and c:IsType(GALAXY_TYPE_UNIT)
end

--部署条件：有植物类单位部署（双方都可触发）
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil)
end

--部署目标
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.filter,1,nil) end
	local g=eg:Filter(s.filter,nil)
	Duel.SetTargetCard(g)
end

--部署操作：给新部署的植物类单位+1/+1
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	local g=Duel.GetTargetsRelateToChain():Filter(Card.IsFaceup,nil)
	local tc=g:GetFirst()
	while tc do
		if tc:IsRace(RACE_PLANT) and tc:IsType(GALAXY_TYPE_UNIT) then
			--攻击力+1
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			--生命值+1
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_HP)
			tc:RegisterEffect(e2)
		end
		tc=g:GetNext()
	end
end

--死亡过滤器：植物类单位
function s.tgfilter(c,tp)
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:IsRace(RACE_PLANT)
		and c:IsType(GALAXY_TYPE_UNIT)
		and c:IsPreviousControler(tp)
end

--死亡条件：有植物类单位死亡
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.tgfilter,1,nil,tp) or eg:IsExists(s.tgfilter,1,nil,1-tp)
end

--死亡目标
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ct1=eg:FilterCount(s.tgfilter,nil,tp)
	local ct2=eg:FilterCount(s.tgfilter,nil,1-tp)
	if ct1>0 then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,ct1,tp,0)
	end
	if ct2>0 then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,ct2,1-tp,0)
	end
end

--死亡操作：给控制者制造星核种子加入手牌
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	--给tp方控制的植物死亡制造星核种子
	local ct1=eg:FilterCount(s.tgfilter,nil,tp)
	if ct1>0 then
		for i=1,ct1 do
			local token=Duel.CreateToken(tp,10000122)
			Duel.SendtoHand(token,tp,REASON_EFFECT)
		end
		--Duel.ConfirmCards(1-tp,Duel.GetFieldGroup(tp,LOCATION_HAND,0))
	end

	--给1-tp方控制的植物死亡制造星核种子
	local ct2=eg:FilterCount(s.tgfilter,nil,1-tp)
	if ct2>0 then
		for i=1,ct2 do
			local token=Duel.CreateToken(1-tp,10000122)
			Duel.SendtoHand(token,1-tp,REASON_EFFECT)
		end
		--Duel.ConfirmCards(tp,Duel.GetFieldGroup(1-tp,LOCATION_HAND,0))
	end
end
