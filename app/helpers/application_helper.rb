module ApplicationHelper
  def title(value)
    unless value.nil?
      @title = "#{value} | Contanko"
    end
  end
end
