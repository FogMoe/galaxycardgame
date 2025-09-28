--给1个友军真菌类单位恢复1点生命值。
local s, id = Import()
function s.initial(c)
	--恢复友军真菌类生命值
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DEFCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetCountLimit(1)
	e1:SetTarget(s.healtg)
	e1:SetOperation(s.healop)
	c:RegisterEffect(e1)
end

--检查是否是自己回合且有可恢复的友军
function s.healcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
		and Duel.IsExistingMatchingCard(s.healfilter,tp,LOCATION_MZONE,0,1,nil)
end

--友军真菌类恢复目标过滤器
function s.healfilter(c)
	return c:IsFaceup() and c:IsType(GALAXY_TYPE_UNIT) and c:IsGalaxyCategory(GALAXY_CATEGORY_FUNGAL)
		and c:GetHp()<c:GetMaxHp()
end

--选择目标
function s.healtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.healfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.healfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.healfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,g,1,0,0)
end

--恢复生命值操作
function s.healop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsLocation(LOCATION_MZONE) then
		--添加已使用效果的客户端提示
		c:RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
		--恢复1点生命值
		Duel.AddHp(tc,1,REASON_EFFECT)
	end
end