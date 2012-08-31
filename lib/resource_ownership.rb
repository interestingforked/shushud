require 'shushu'
require 'utils'

module Shushu
  module ResourceOwnership
    extend self

    ACTIVE = 1
    INACTIVE = 0

    def handle_in(state, provider_id, account_id, resid, time, eid)
      case state
      when "active"
        if prev_activated?(eid)
          [200, Utils.enc_j(id: eid)]
        elsif o = create_ownership(provider_id,account_id,resid,ACTIVE,time,eid)
          [201, Utils.enc_j(o)]
        else
          [400, Utils.enc_j(error: "invalid args")]
        end
      when "inactive"
        if prev_deactivated?(eid)
          [200, Utils.enc_j(id: eid)]
        elsif o = create_ownership(provider_id,account_id,resid,INACTIVE,time,eid)
          [201, Utils.enc_j(o)]
        else
          [400, Utils.enc_j(error: "invalid args")]
        end
      end
    end

    private

    def prev_activated?(eid)
      ! DB[:resource_ownership_records].
        where(state: ACTIVE).
        where(entity_id: eid).
        count.
        zero?
    end

    def prev_deactivated?(eid)
      ! DB[:resource_ownership_records].
        where(state: INACTIVE).
        where(entity_id: eid).
        count.
        zero?
    end

    def create_ownership(provider_id, account_id, resid, state, time, eid)
      log(measure: true, fn: [provider_id, __method__].join("-")) do
        DB[:resource_ownership_records].
          returning(:entity_id).
          insert(provider_id: provider_id,
                  owner: account_id,
                  resource_id: resid,
                  state: state,
                  time: time,
                  entity_id: eid,
                  created_at: Time.now).pop
      end
    end

    def log(data, &blk)
      Scrolls.log({ns: "resource_ownership"}.merge(data), &blk)
    end

  end
end
