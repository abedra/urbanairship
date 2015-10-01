require 'spec_helper'
require 'urbanairship'

describe Urbanairship::Devices do
  
  # create an array of size n
  def build_array(n)
    dummy_id = { 'device_type' => 'android',
                 'channel_id' => '01000001-01010000-01010000-01001100' }
    Array.new(n, dummy_id)
  end

  describe Urbanairship::Devices::ChannelUninstall do
    example_hash = {
      :body => {
        :ok => 'true'
      },
      :code => '202'
    }
    let(:simple_http_response) { example_hash }

    describe '#uninstall' do
      it 'can be invoked and parse the "ok" value' do
        airship = UA::Client.new(key: '123', secret: 'abc')
        allow(airship)
          .to receive(:send_request)
          .and_return(simple_http_response)
        cu = UA::ChannelUninstall.new(client: airship)
        resp = cu.uninstall(channels: build_array(1))
        ok = resp[:body][:ok] || 'None'
        expect(ok).to eq 'true'
      end

      it 'fails with over 200 channels' do
        airship = UA::Client.new(key: '123', secret: 'abc')
        allow(airship)
          .to receive(:send_request)
          .and_return(simple_http_response)
        cu = UA::ChannelUninstall.new(client: airship)

        expect {
          cu.uninstall(channels: build_array(201))
        }.to raise_error(ArgumentError)
      end
    end
  end
end
