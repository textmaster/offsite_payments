require 'test_helper'

class RemotePayboxTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Paybox::Helper.new(
      'order_id',
      fixtures(:paybox)[:site],
      :amount => 500,
      :currency => 'EUR',
      :credential2 => fixtures(:paybox)[:rank],
      :credential3 => fixtures(:paybox)[:identifier],
      :credential4 => fixtures(:paybox)[:secret_key],
      :notify_url => 'http://example.com/notify_url',
      :return_url => 'http://example.com/return_url',
    )

    @helper.customer = { :email => 'test@paybox.com' }
  end

  def test_post
    response = Net::HTTP.post_form(URI(Paybox.service_url), @helper.form_fields)

    assert response.body.include?('order_id')
  end

end
