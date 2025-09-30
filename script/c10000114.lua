--深渊观测者：部署时支付1补给，查看对手卡组顶3张，选择2张加入己手，其余送至对手手牌。
local s,id=Import()

function s.initial(c)
    -- 部署成功：改写双方手牌
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCost(s.cost)
    e1:SetTarget(s.toptg)
    e1:SetOperation(s.topop)
    c:RegisterEffect(e1)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckSupplyCost(tp,1) end
    Duel.PaySupplyCost(tp,1)
end

function s.toptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(1-tp,GALAXY_LOCATION_BASIC_DECK,0)>=3 end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,tp,2)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,0,1-tp,1)
end

function s.topop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(1-tp,GALAXY_LOCATION_BASIC_DECK,0)<3 then return end
    Duel.DisableShuffleCheck()
    Duel.ConfirmDecktop(1-tp,3)
    local g=Duel.GetDecktopGroup(1-tp,3)
    if #g==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local pick=g:Select(tp,math.min(2,#g),math.min(2,#g),nil)
    if #pick>0 then
        Duel.SendtoHand(pick,tp,REASON_EFFECT)
        g:Sub(pick)
    end
    if #g>0 then
        Duel.SendtoHand(g,1-tp,REASON_EFFECT)
    end
    Duel.ShuffleHand(tp)
    Duel.ShuffleHand(1-tp)
end
