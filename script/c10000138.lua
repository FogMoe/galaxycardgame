--战斗辅助构件
--部署时，制造1张电磁增幅器（10000139）加入手卡。

local s,id = Import()
function s.initial(c)
	-- 部署时，制造1张电磁增幅器加入手卡
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 创建1张电磁增幅器
	local token=Duel.CreateToken(tp,10000139)
	if token then
		Duel.SendtoHand(token,nil,REASON_EFFECT)
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND) or c:IsPreviousLocation(LOCATION_EXTRA)
end
