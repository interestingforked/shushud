module Shushu
  module ResourceOwnership
    extend self

    ACTIVE = 1
    INACTIVE = 0

    def handle_in(state, provider_id, account_id, resource_id, time, entity_id)
      case state
      when "active"
        activate(provider_id, account_id, resource_id, time, entity_id)
      when "inactive"
        deactivate(provider_id, account_id, resource_id, time, entity_id)
      end
    end

    def activate(provider_id, account_id, resid, time, eid)
      [200,
        create_record(provider_id, account_id, resid, ACTIVE, time, eid)]
    end

    def deactivate(provider_id, account_id, resid, time, eid)
      [200,
        create_record(provider_id, account_id, resid, INACTIVE, time, eid)]
    end

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
