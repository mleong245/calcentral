require 'spec_helper'

describe CampusSolutions::Address do

  context 'post' do
    let(:params) { {} }
    let(:fake_proxy) { CampusSolutions::Address.new(fake: true, user_id: random_id, params: params) }

    context 'filtering out fields not on the whitelist' do
      let(:params) { {
        bogus: 1,
        invalid: 2,
        address1: '1 Test Lane'
      } }
      subject { fake_proxy.filter_updateable_params(params) }
      it 'should strip out invalid fields' do
        expect(subject.keys.length).to eq 1
        expect(subject[:bogus]).to be_nil
        expect(subject[:invalid]).to be_nil
        expect(subject[:address1]).to eq '1 Test Lane'
      end
    end

    context 'converting params to Campus Solutions field names' do
      let(:params) { {
        addressType: 'HOME',
        address1: '1 Test Lane'
      } }
      subject {
        result = fake_proxy.construct_cs_post(params)
        MultiXml.parse(result)['UC_CC_ADDR_UPD_REQ']
      }
      it 'should convert the CalCentral params to Campus Solutions params without exploding on bogus fields' do
        expect(subject['ADDRESS1']).to eq '1 Test Lane'
        expect(subject['ADDRESS_TYPE']).to eq 'HOME'
      end
    end

    context 'performing a post' do
      let(:params) { {
        addressType: 'HOME',
        address1: '1 Test Lane'
      } }
      subject {
        fake_proxy.get
      }
      it 'should make a successful post' do
        expect(subject[:statusCode]).to eq 200
        expect(subject[:feed][:address]).to be
      end
    end
  end

  context 'with a real external service', :testext => true do
    let(:params) { {
      addressType: 'HOME',
      address1: '1 Test Lane',
      address2: 'peters road',
      city: 'ventura',
      state: 'CA',
      postal: '93001',
      country: 'USA'
    } }
    let(:real_proxy) { CampusSolutions::Address.new(fake: false, user_id: random_id, params: params) }

    context 'performing a real post' do
      subject {
        real_proxy.get
      }
      it 'should make a successful REAL post' do
        expect(subject[:statusCode]).to eq 200
        expect(subject[:feed][:address]).to be
      end
    end
  end
end
