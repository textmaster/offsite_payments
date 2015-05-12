require 'test_helper'

class PayboxHelperTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @helper = Paybox::Helper.new(
      'order_id',
      fixtures(:paybox)[:site],
      :amount => 5.00,
      :currency => 'USD',
      :credential2 => fixtures(:paybox)[:rank],
      :credential3 => fixtures(:paybox)[:identifier],
      :credential4 => fixtures(:paybox)[:secret_key],
      :notify_url => 'notify_url',
      :return_url => 'return_url',
    )
  end

  def test_basic_helper_fields
    assert_field 'PBX_SITE', fixtures(:paybox)[:site]
    assert_field 'PBX_RANG', fixtures(:paybox)[:rank]
    assert_field 'PBX_IDENTIFIANT', fixtures(:paybox)[:identifier]

    assert_field 'PBX_TOTAL', '5.0'

    assert_field 'PBX_CMD', 'order_id'

    assert_field 'PBX_REPONDRE_A', 'notify_url'
    assert_field 'PBX_EFFECTUE', 'return_url'
  end

  def test_cancel_return_url
    @helper.cancel_return_url = 'cancel_return_url'

    assert_field 'PBX_REFUSE', 'cancel_return_url'
  end

  def test_refuse_return_url
    @helper.refuse_return_url = 'refuse_return_url'

    assert_field 'PBX_ANNULE', 'refuse_return_url'
  end


  def test_custom_fields
    assert_field 'PBX_HASH', 'SHA512'
  end

  def test_customer_fields
    @helper.customer :email => 'cody@example.com'

    assert_field 'PBX_PORTEUR', 'cody@example.com'
  end

  def test_unknown_currency
    assert_raises ArgumentError do
      @helper.currency = 'INV'
    end
  end

  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'

    assert_equal 9, @helper.fields.size
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end

  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end
end
