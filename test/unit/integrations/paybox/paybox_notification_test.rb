require 'test_helper'

class PayboxNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @paybox = Paybox::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @paybox.complete?
    assert_equal "Completed", @paybox.status
    assert_equal "order.test 123", @paybox.transaction_id
    assert_equal "order.test 123", @paybox.item_id
    assert_equal 5.0, @paybox.gross
    assert_equal nil, @paybox.currency
    assert_equal "XXXXXX", @paybox.security_key
    assert_equal "", @paybox.received_at
    assert @paybox.test?
  end

  def test_custom_accessors
    assert_equal "00000", @paybox.status_code
  end

  def test_acknowledgement
    assert @paybox.acknowledge(fixtures(:paybox)[:public_key])
  end


  def test_respond_to_acknowledge
    assert @paybox.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    "amount=500&reference=order.test%20123&autorization=XXXXXX&error=00000&sign=I7BPIUeM1Rl%2B7QW1Ew6gYfux4oyQGhA6ra6wKyusxrwQpXocYzu9z9%2Fbgomm%2FpFYLGfIQs1GrRVN0tDoERzPgKnU0m2yYAyqQNfuRXkOioDC7NtgYKLsPcf4eyzHWOIxe1Wx8L5lOiyBBINvubmWjCt9mjFCtPrSXxR48TWrKmM%3D"
  end
end
