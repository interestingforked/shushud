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
        if create_record(provider_id, account_id, resid, ACTIVE, time, eid)
          [200, Utils.enc_j(msg: "OK")]
        else
          [400, Utils.enc_j(error: "invalid args")]
        end
      when "inactive"
        if create_record(provider_id, account_id, resid, INACTIVE, time, eid)
          [200, Utils.enc_j(msg: "OK")]
        else
          [400, Utils.enc_j(error: "invalid args")]
        end
      end
    end

    private

    def create_record(provider_id, account_id, resid, state, time, eid)
      DB[:resource_ownership_records].
        returning.
        insert(provider_id: provider_id,
                owner: account_id,
                hid: resid,
                state: state,
                time: time,
                entity_id: eid,
                created_at: Time.now).pop
    end

  end
end
