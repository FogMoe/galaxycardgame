--孢子体 1/1的真菌类令牌单位
--被攻击时，掷硬币：正面时随机制造1个补给1的真菌类单位并部署。
local s, id = Import()
function s.initial(c)
	--被攻击时，掷硬币正面时随机制造1个补给1的真菌类单位并部署
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_COIN)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BE_BATTLE_TARGET)
	e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetCountLimit(1)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

--被攻击时的基本条件检查
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE) > 0
		and s.get_random_fungal_unit() ~= nil
end

--目标函数：设置硬币和特殊召唤信息
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.spcon(e,tp,eg,ep,ev,re,r,rp) end
	Duel.SetOperationInfo(0,CATEGORY_COIN,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

--随机获取补给1的真菌类单位
function s.get_random_fungal_unit()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE race = %d
		AND level = 1
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], RACE_REPTILE, TYPE_MONSTER, TYPE_TOKEN)

	local results = Duel.QueryDatabase(sql)
	if results and not results.error and #results > 0 then
		return results[1].id
	end
	return nil
end

--特殊召唤操作
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE) <= 0 then return end
	--添加已使用效果的客户端提示
	e:GetHandler():RegisterFlagEffect(0,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,1))
	--掷硬币
	local coin = Duel.TossCoin(tp,1)
	if coin == 1 then  --正面时才特殊召唤
		local card_id = s.get_random_fungal_unit()
		if card_id then
			local token = Duel.CreateToken(tp, card_id)
			if token then
				Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
			end
		end
	end
end