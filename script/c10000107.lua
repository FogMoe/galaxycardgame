--纳米构造体：补给2的机械单位。部署成功时检索1张强化支援（装备）卡；若装备着强化卡，则部署回合即可攻击。
local s,id=Import()

function s.initial(c)
    -- 部署成功：从卡组或弃牌区加入1张装备到手牌
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- 装备着强化卡时，本回合可攻击（Rush）
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_RUSH)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(GALAXY_LOCATION_UNIT_ZONE)
    e2:SetCondition(s.rushcon)
    c:RegisterEffect(e2)
end

function s.thfilter(c)
    return c:IsType(TYPE_EQUIP) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,
            GALAXY_LOCATION_BASIC_DECK+GALAXY_LOCATION_DISCARD,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,
        GALAXY_LOCATION_BASIC_DECK+GALAXY_LOCATION_DISCARD,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end

function s.rushcon(e)
    local c=e:GetHandler()
    return c:IsFaceup() and c:GetEquipGroup():IsExists(Card.IsType,1,nil,TYPE_EQUIP)
end
