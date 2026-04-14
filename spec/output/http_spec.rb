require_relative '../spec_helper'
require 'oxidized/output/http'

describe Oxidized::Output::Http do
  before(:each) do
    Oxidized.asetus = Asetus.new
  end

  it 'skips nested header config values when building the request' do
    Oxidized.config.output.http.url = 'https://example.test/oxidized'
    Oxidized.config.output.http.headers = Asetus::ConfigStruct.new(
      {
        'Accept-Encoding' => { 'count' => { '>' => {} } },
        'X-Test' => 'ok'
      }
    )

    output = Oxidized::Output::Http.new
    outputs = stub(to_cfg: 'router config')

    response = mock('Net::HTTPResponse')
    response.stubs(:code).returns('200')

    request = nil
    net_http = mock('Net::HTTP')
    net_http.expects(:use_ssl=).with(true)
    net_http.expects(:verify_mode=)
    net_http.expects(:request).with do |req|
      request = req
      true
    end.returns(response)
    Net::HTTP.expects(:new).with('example.test', 443).returns(net_http)

    Oxidized::Output::Http.logger.expects(:warn)
                          .with("Skipping invalid HTTP output header \"Accept-Encoding\": value must be scalar")

    output.store('router1', outputs)

    _(request['X-Test']).must_equal 'ok'
    _(request['Accept-Encoding']).wont_match(/Asetus::ConfigStruct/)
    _(request['Content-Type']).must_equal 'application/json'
  end
end
