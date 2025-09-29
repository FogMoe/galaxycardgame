--单位：部署（特招成功）时，制造2张机械模块强化支援卡（createtoken 10000104 10000105），选择1张加入手牌。
local s,id=Import()

function s.initial(c)
    -- 部署成功：创造模块并让玩家选择加入手牌
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOKEN+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCondition(s.tkcon)
    e1:SetTarget(s.tktg)
    e1:SetOperation(s.tkop)
    c:RegisterEffect(e1)
end

function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,tp,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,GALAXY_LOCATION_HAND_CARDS)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
    local created=Group.CreateGroup()
    for _,code in ipairs({10000104,10000105}) do
        local token=Duel.CreateToken(tp,code)
        if token then
            created:AddCard(token)
        end
    end
    if #created>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local pick=created:Select(tp,1,1,nil)
        if #pick>0 then
            Duel.SendtoHand(pick,nil,REASON_EFFECT)
        end
        created:DeleteGroup()
    end
end
