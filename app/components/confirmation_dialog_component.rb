class ConfirmationDialogComponent < ViewComponent::Base
  def initialize(title:, message:, confirm_url:, confirm_label: "Confirm", cancel_label: "Cancel", method: :post)
    @title = title
    @message = message
    @confirm_url = confirm_url
    @confirm_label = confirm_label
    @cancel_label = cancel_label
    @method = method
  end
end
