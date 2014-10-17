require 'spec_helper'
describe 'openswan' do

  context 'with defaults for all parameters' do
    it { should contain_class('openswan') }
  end
end
