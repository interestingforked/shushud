module Resolvable

  # Purpose:
  #
  # Include this module into a Sequel::Model to allow for slug resolution.
  # The idea is that some models will have a foreign key, say a
  # payment_method_id. When the client deals with an API of such a model they
  # may not know the foreign_key's value, they may only know a slug that
  # represents the dereferenced foreign key. So they will pass the slug as the
  # id of the foreign_key. We should be smart an convert the slug to the
  # foreign_key on the client's behalf.

  def resolve(model, fk, slug)
    self[fk] = resolve_pk(model, fk, slug)
  end

  private

  def resolve_pk(model, fk, slug)
    if scope(model).filter(:id => self[fk]).count == 1
      Log.info("##{fk}_resolution resolved by #{fk}")
      scope(model).filter(:id => self[fk]).first[:id]
    elsif scope(model).filter(slug => self[fk].to_s).count == 1
      Log.info("##{fk}_resolution resolved by #{slug}")
      scope(model).filter(slug => self[fk].to_s).first[:id]
    else
      Log.error("##{fk}_resolution unable to resolve with fk=#{fk} slug=#{slug} provider=#{self[:provider_id]}")
      self[fk]
    end
  end

  def scope(model)
    model.filter(:provider_id => self[:provider_id])
  end

end
