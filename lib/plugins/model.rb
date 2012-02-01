class Sequel::Model

  include CreatedAtSetter

  def before_create
    set_created_at
  end

end
