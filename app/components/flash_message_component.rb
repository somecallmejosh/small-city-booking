class FlashMessageComponent < ViewComponent::Base
  VARIANTS = {
    notice: {
      container: "bg-green-50 border border-green-200 text-green-900",
      icon: "text-green-500",
      role: "status"
    },
    alert: {
      container: "bg-orange-50 border border-orange-200 text-orange-900",
      icon: "text-orange-500",
      role: "alert"
    },
    error: {
      container: "bg-red-50 border border-red-200 text-red-900",
      icon: "text-red-500",
      role: "alert"
    }
  }.freeze

  def initialize(type:, message:)
    @type = type.to_sym
    @message = message
  end

  def container_classes
    VARIANTS.fetch(@type, VARIANTS[:alert])[:container]
  end

  def icon_classes
    VARIANTS.fetch(@type, VARIANTS[:alert])[:icon]
  end

  def aria_role
    VARIANTS.fetch(@type, VARIANTS[:alert])[:role]
  end
end
