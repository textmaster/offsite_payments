module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Paybox

      # Overwrite this if you want to change the Paybox test url
      mattr_accessor :test_url
      self.test_url = 'https://preprod-tpeweb.paybox.com/cgi/MYchoix_pagepaiement.cgi'

      # Overwrite this if you want to change the Paybox production url
      mattr_accessor :production_url
      #self.production_url = 'https://www.paypal.com/cgi-bin/webscr'

      def self.service_url
        mode = OffsitePayments.mode
        case mode
        when :production
          production_url
        when :test
          test_url
        else
          fail StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        SUPPORTED_CURRENCIES = %w(USD EUR XAF)

        mapping :account, 'PBX_SITE'
        mapping :credential2, 'PBX_RANG'
        mapping :credential3, 'PBX_IDENTIFIANT'

        mapping :amount, 'PBX_TOTAL'

        mapping :order, 'PBX_CMD'

        mapping :customer, :email => 'PBX_PORTEUR'

        mapping :notify_url, 'PBX_REPONDRE_A'
        mapping :return_url, 'PBX_EFFECTUE'
        mapping :cancel_return_url, 'PBX_REFUSE'
        mapping :refuse_return_url, 'PBX_ANNULE'

        attr_reader :secret_key

        def initialize(order, account, options = {})
          super

          @secret_key = options[:credential4]
          add_field('PBX_HASH', 'SHA512')
          add_field('PBX_TIME', date_iso)
          add_field('PBX_PAYBOX', Paybox.service_url)

          # POST to the IPN url, instead of the default GET
          add_field('PBX_RUF1', 'POST')

          # Configure the notificiation reponse.
          #
          # Format: <desired_field_name>:<key>
          #
          # Where the signature('K' key) must be last.
          #
          # M - AMount of the transaction (given in PBX_TOTAL).
          # R - Reference of the order (given in PBX_CMD) : space URL encoded
          # A - Authorization number (reference given by the authorization center) : URL encoded
          # E - Response code of the transaction
          # Q - Transaction timestamp. Format: HH:MM:SS (24h)
          # W - Transaction processing date on the Paybox platform. Format: DDMMYYYY
          # K - Signature of the fields in the URL. Format: url-encoded
          add_field('PBX_RETOUR', 'amount:M;reference:R;autorization:A;error:E;time:Q;date:W;sign:K')

          add_field('PBX_DEVISE', @currency)

          @fields = Hash[@fields.sort]
        end

        def currency=(value)
          fail ArgumentError, "#{value} is not supported currency" unless SUPPORTED_CURRENCIES.include?(value.to_s)

          @currency = Money::Currency.find(value).iso_numeric
          value
        end

        def form_fields
          @fields.merge('PBX_HMAC' => signature)
        end

        def date_iso
          Time.now.utc.iso8601
        end

        def query
          @fields.to_a.map { |f| f.join('=') }.join('&')
        end

        def binary_key
          [secret_key].pack("H*")
        end

        def signature
          OpenSSL::HMAC.hexdigest(
            OpenSSL::Digest.new('sha512'),
            binary_key,
            query
          ).upcase
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          status == 'Completed'
        end

        def item_id
          transaction_id
        end

        def transaction_id
          params['reference']
        end

        # When was this payment received by the client.
        def received_at
          p params
          params['']
        end

        def payer_email
          params['']
        end

        def receiver_email
          params['']
        end

        def security_key
          params['autorization']
        end

        # the money amount we received in X.2 decimal.
        def gross
          Money.new(params['amount'].to_i).to_d
        end

        def currency
          nil
        end

        # Was this a test transaction?
        def test?
          params['autorization'] == 'XXXXXX'
        end

        def status_code
          params['error']
        end

        def status
          status_code == '00000' ? 'Completed' : 'Failed'
        end

        # Acknowledge the transaction to Paybox. This method has to be called after a new
        # apc arrives. Paybox will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = PayboxNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          digest = OpenSSL::Digest::SHA1.new
          public_key = OpenSSL::PKey::RSA.new(authcode)

          request_params, _, request_sign = payload.rpartition('&sign=')

          sign = Base64.decode64(Rack::Utils.unescape(request_sign))

          public_key.verify(digest, sign, request_params)
        end
      end
    end
  end
end
