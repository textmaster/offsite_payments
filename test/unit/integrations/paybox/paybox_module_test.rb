require 'test_helper'

class PayboxTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Paybox::Notification, Paybox.notification('name=cody')
  end
end
