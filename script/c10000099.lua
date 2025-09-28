--机械回收者
--每当友方机械类单位死亡，制造1个它的1/1复制体，补给变为1，加入卡组
local s, id = Import()
function s.initial(c)
	--监控友方机械类单位死亡
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--友方机械类单位死亡条件
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.filter,1,nil,tp)
end

--友方机械类单位过滤器
function s.filter(c,tp)
	return c:IsPreviousControler(tp)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsRace(RACE_MACHINE)
		and c:IsType(TYPE_MONSTER)
end

--目标设置
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.filter,1,nil,tp) end
	local g=eg:Filter(s.filter,nil,tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,g:GetCount(),tp,0)
end

--制造复制体并加入卡组
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end

	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	local created_tokens=Group.CreateGroup()

	for tc in aux.Next(g) do
		--获取原单位信息
		local code=tc:GetOriginalCode()
		local atk=tc:GetBaseAttack()
		local def=tc:GetBaseDefense()
		local race=tc:GetRace()
		local attribute=tc:GetAttribute()

		--创建1/1复制体token
		local token=Duel.CreateToken(tp,code)
		if token then
			--修改为1/1并设置补给为1
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_BASE_ATTACK)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1)

			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_BASE_DEFENSE)
			e2:SetValue(1)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e2)

			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_CHANGE_LEVEL)
			e3:SetValue(1)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e3)

			--添加客户端提示
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			e4:SetDescription(aux.Stringid(id,1))
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e4)

			created_tokens:AddCard(token)
		end
	end

	--将创建的复制体加入卡组
	if created_tokens:GetCount()>0 then
		Duel.ConfirmCards(1-tp,created_tokens)
		Duel.SendtoDeck(created_tokens,tp,2,REASON_EFFECT)
	end
end