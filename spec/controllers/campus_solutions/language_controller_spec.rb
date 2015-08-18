require 'spec_helper'

describe LanguageController do
  context 'language feed' do
    let(:feed) { :get }
    it_behaves_like 'an unauthenticated user'
    context 'authenticated user' do
      let(:user) { random_id }
      let(:feed_key) { 'accomplishments' }
      it_behaves_like 'a successful feed'
    end
  end

  context 'updating language' do
    it 'should not let an unauthenticated user post' do
      post :post, {format: 'json', uid: '100'}
      expect(response.status).to eq 401
    end

    context 'authenticated user' do
      before do
        session['user_id'] = '1234'
        User::Auth.stub(:where).and_return([User::Auth.new(uid: '1234', is_superuser: false, active: true)])
      end
      it 'should let an authenticated user post' do
        post :post,
             {
               bogus_field: 'abc',
               languageCode: 'EN',
               isNative: 'N',
               isTranslateToNative: 'N',
               isTeachLanguage: 'N',
               speakProf: '1',
               readProf: '2',
               teachLang: '3'
             }
        expect(response.status).to eq 200
        json = JSON.parse(response.body)
        expect(json['statusCode']).to eq 200
        expect(json['feed']).to be
        expect(json['feed']['status']).to be
      end
    end
  end

end

