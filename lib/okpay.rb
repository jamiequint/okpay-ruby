require 'savon'

module Okpay
  class API
    class Client

      def okpay_camelize(str)
        result = str.gsub(/^[a-z]|[\s_]+[a-z]/) { |a| a.upcase }
        result = result.gsub(/[\s_]/, '')
        result
      end

      DEFAULTS = {
        :wsdl => File.join(File.dirname(File.expand_path(__FILE__)), '../config/wsdl.xml')
      }

      METHODS = {
        :get_date_time => [],
        :wallet_get_balance => [],
        :wallet_get_currency_balance => [:currency],
        :send_money => [:reciever, :currency, :amount, :comment, :is_receiver_pays_fees, :invoice],
        :account_check => [:account],
        :transaction_get => [:txn_id, :invoice],
        :transaction_history => [:from, :till, :page_size, :page_number],
        :debiit_card_prepay => [:email, :currency, :is_courier_delivery, :comment],
        :withdraw_to_ecurrency => [:payment_method, :pay_system_account, :amount, :currency, :fees_from_amount, :invoice],
        :withdraw_to_ecurrency_calculate => [:payment_method, :amount, :currency, :fees_from_amount]
      }

      def initialize(wallet_id, api_key, options={})
        @api_key = api_key.strip
        @wallet_id = wallet_id.strip
        @config = DEFAULTS.merge! options
        @soap_client = Savon.client(wsdl: @config[:wsdl])
      end

      METHODS.each_pair do |method,args|
        class_eval %{
          def #{method}(#{args.join(',')})
            message = {"WalletID" => @wallet_id, "SecurityToken" => security_token}
            #{args}.each do |arg|
              message[okpay_camelize(arg.to_s)] = eval arg.to_s
            end
            response = @soap_client.call(:#{method}, message: message)
            response.body[:#{method}_response][:#{method}_result]
          end
        }
      end

      private

      def security_token
        okpay_timestamp = Time.now.utc.strftime('%Y%m%d:%H')
        Digest::SHA256.hexdigest("#{@api_key}:#{okpay_timestamp}").to_s.upcase
      end

    end
  end
end
