--寄生脑虫
--死亡时，这张卡加入对手的卡组顶部，然后永久移除此效果。

local s,id=Import()

function s.initial(c)
	-- 死亡时加入对手卡组顶部（只能使用一次）
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCondition(s.tdcon)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)
end

-- 条件：从场上送去墓地，且没有已触发标记
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 必须从场上送去墓地，且没有已触发标记
	return c:IsPreviousLocation(GALAXY_LOCATION_UNIT_ZONE)
		and c:GetFlagEffect(id)==0
end

-- 目标
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

-- 操作：加入对手卡组顶部，然后永久移除此效果
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		-- 将这张卡加入对手的卡组顶部
		if Duel.SendtoDeck(c,1-tp,SEQ_DECKTOP,REASON_EFFECT)>0 then
			-- 注册已触发标记，永久移除此效果
			c:RegisterFlagEffect(id,0,EFFECT_FLAG_CANNOT_DISABLE,1)

			-- 添加客户端提示
			local e1=Effect.CreateEffect(c)
			e1:SetDescription(aux.Stringid(id,1))
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
			c:RegisterEffect(e1)
		end
	end
end
