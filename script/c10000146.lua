--政策树
--消耗2点补给，选择1项效果使用（
--外交：制造1张星际宣言加入手卡。
--繁荣：制造1张运送补给和1张补给线加入卡组top。
--霸权：随机制造1张补给2的军团单位加入手卡，使其获得效果（部署时不消耗补给）。
--)

local s,id=Import()

function s.initial(c)
	-- 发动
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-- 消耗2点补给
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckSupplyCost(tp,2) end
	Duel.PaySupplyCost(tp,2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- 让玩家选择3个选项之一
	local sel=Duel.SelectOption(tp,
		aux.Stringid(id,1),  -- 选项1：外交
		aux.Stringid(id,2),  -- 选项2：繁荣
		aux.Stringid(id,3))  -- 选项3：霸权

	if sel==0 then
		-- 选项1：外交 - 制造1张星际宣言加入手卡
		local token=Duel.CreateToken(tp,10000144)
		if token then
			Duel.SendtoHand(token,nil,REASON_EFFECT)
		end

	elseif sel==1 then
		-- 选项2：繁荣 - 制造1张运送补给和1张补给线加入卡组
		local g=Group.CreateGroup()

		-- 创建运送补给
		local token1=Duel.CreateToken(tp,10000009)
		if token1 then
			g:AddCard(token1)
		end

		-- 创建补给线
		local token2=Duel.CreateToken(tp,10000032)
		if token2 then
			g:AddCard(token2)
		end

		if #g>0 then
			-- 展示给对手看
			Duel.ConfirmCards(1-tp,g)
			-- 洗入卡组顶部
			Duel.SendtoDeck(g,tp,SEQ_DECKTOP,REASON_EFFECT)
		end

	elseif sel==2 then
		-- 选项3：霸权 - 随机制造1张补给2的军团单位加入手卡
		local card_id=s.get_random_legion_unit()
		if card_id then
			-- 创建token
			local token=Duel.CreateToken(tp,card_id)
			if token then
				-- 加入手卡
				Duel.SendtoHand(token,nil,REASON_EFFECT)

				-- 给卡片添加免补给部署效果
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_FREE_DEPLOY)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				token:RegisterEffect(e1)

				-- 添加客户端hint提示
				local e2=Effect.CreateEffect(e:GetHandler())
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e2:SetDescription(aux.Stringid(id,4))
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				token:RegisterEffect(e2)
			end
		end
	end
end

-- 随机获取1张军团单位（补给2）
function s.get_random_legion_unit()
	local sql = string.format([[
		SELECT id FROM datas
		WHERE attribute = %d
		AND level = 2
		AND type & %d != 0
		AND type & %d = 0
		AND id BETWEEN 10000000 AND 99999999
		ORDER BY RANDOM()
		LIMIT 1
	]], ATTRIBUTE_EARTH, TYPE_MONSTER, TYPE_TOKEN)

	local results = Duel.QueryDatabase(sql)
	if results and not results.error and #results > 0 then
		return results[1].id
	end
	return nil
end
