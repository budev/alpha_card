# frozen_string_literal: true

# typed: false
require 'spec_helper'

describe AlphaCard::Response do
  let(:successful_response_mock) do
    'authcode=083319&avsresponse=&cvvresponse=M&orderid=1&response=1&response_code=100&responsetext=AP&transactionid=2303767426&type=sale'
  end

  let(:declined_response_mock) do
    'authcode=&avsresponse=&cvvresponse=&orderid=1&response=2&response_code=220&responsetext=INVLD+ACCT&transactionid=2302720045&type=sale'
  end

  let(:error_response_mock) do
    'authcode=&avsresponse=U&cvvresponse=&orderid=1&response=3&response_code=220&responsetext=ERROR&transactionid=2302620041&type=sale'
  end

  context 'successful request' do
    let(:response) { AlphaCard::Response.new(successful_response_mock) }

    it '#success? = true' do
      expect(response.success?).to be_truthy
    end

    it 'returns response code' do
      expect(response.code).to eq('100')
    end

    it 'returns Transaction ID' do
      expect(response.transaction_id).to eq('2303767426')
    end

    it 'returns CVV response message' do
      expect(response.cvv_response).to eq('CVV2/CVC2 match')
    end

    it 'returns blank AVS response message' do
      expect(response.avs_response).to be_nil
    end

    it 'returns Order ID' do
      expect(response.order_id).to eq('1')
    end

    it 'returns response message' do
      expect(response.message).to eq('Transaction was approved')
    end

    it 'returns auth code' do
      expect(response.auth_code).to eq('083319')
    end

    it 'returns credit card authorization message' do
      expect(response.credit_card_auth_message).to eq('Approved or completed successfully')
    end
  end

  context 'declined request' do
    let(:response) { AlphaCard::Response.new(declined_response_mock) }

    it '#declined? = true' do
      expect(response.declined?).to be_truthy
    end

    it 'returns responce code' do
      expect(response.code).to eq('220')
    end

    it 'returns Transaction ID' do
      expect(response.transaction_id).to eq('2302720045')
    end

    it 'returns Order ID' do
      expect(response.order_id).to eq('1')
    end

    it 'returns response message' do
      expect(response.message).to eq('Incorrect payment information')
    end

    it "doesn't returns auth code" do
      expect(response.auth_code).to be_nil.or(be_empty)
    end
  end

  context 'error request' do
    let(:response) { AlphaCard::Response.new(error_response_mock) }

    it '#error? = true' do
      expect(response.error?).to be_truthy
    end

    it 'returns responce code' do
      expect(response.code).to eq('220')
    end

    it 'returns Transaction ID' do
      expect(response.transaction_id).to eq('2302620041')
    end

    it 'returns Order ID' do
      expect(response.order_id).to eq('1')
    end

    it 'returns AVS response message' do
      expect(response.avs_response).to eq('Address unavailable')
    end

    it 'returns response message' do
      expect(response.message).to eq('Incorrect payment information')
    end

    it "doesn't returns auth code" do
      expect(response.auth_code).to be_nil.or(be_empty)
    end
  end
end
