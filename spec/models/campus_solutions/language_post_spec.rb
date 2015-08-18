require 'spec_helper'

describe CampusSolutions::LanguagePost do

  context 'post' do
    let(:params) { {} }
    let(:fake_proxy) { CampusSolutions::LanguagePost.new(fake: true, user_id: random_id, params: params) }

    context 'filtering out fields not on the whitelist' do
      let(:params) { {
        bogus: 1,
        invalid: 2,
        isNative: 'N'
      } }
      subject { fake_proxy.filter_updateable_params(params) }
      it 'should strip out invalid fields' do
        expect(subject.keys.length).to eq 1
        expect(subject[:bogus]).to be_nil
        expect(subject[:invalid]).to be_nil
        expect(subject[:isNative]).to eq 'N'
      end
    end

    context 'converting params to Campus Solutions field names' do
      let(:params) { {
        isNative: 'N',
        languageCode: 'ZZ'
      } }
      subject {
        result = fake_proxy.construct_cs_post(params)
        MultiXml.parse(result)['Languages']
      }
      it 'should convert the CalCentral params to Campus Solutions params without exploding on bogus fields' do
        expect(subject['JPM_CAT_ITEM_ID']).to eq 'ZZ'
        expect(subject['NATIVE_LANGUAGE']).to eq 'N'
      end
    end

    context 'performing a post' do
      let(:params) { {
        languageCode: 'EN',
        isNative: 'N',
        isTranslateToNative: 'N',
        isTeachLanguage: 'N',
        speakProf: '1',
        readProf: '2',
        teachLang: '3'
      } }
      subject {
        fake_proxy.get
      }
      it 'should make a successful post' do
        expect(subject[:statusCode]).to eq 200
        expect(subject[:feed][:status]).to be
      end
    end
  end

  context 'with a real external service', :testext => true do
    let(:params) { {
      languageCode: 'EN',
      isNative: 'N',
      isTranslateToNative: 'N',
      isTeachLanguage: 'N',
      speakProf: '1',
      readProf: '2',
      teachLang: '3'
    } }
    let(:real_proxy) { CampusSolutions::LanguagePost.new(fake: false, user_id: random_id, params: params) }

    context 'performing a real post' do
      subject {
        real_proxy.get
      }
      it 'should make a successful REAL post' do
        expect(subject[:statusCode]).to eq 200
        expect(subject[:feed][:status]).to be
      end
    end
  end
end
