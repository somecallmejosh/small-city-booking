class HelpController < ApplicationController
  allow_unauthenticated_access

  def index; end
  def getting_started; end
  def calendar; end
  def checkout; end
  def cancellations; end
  def notifications; end
  def account; end
  def terms; end
end
