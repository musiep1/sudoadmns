require 'spec_helper'
describe 'sudoadmns' do

  context 'with defaults for all parameters' do
    it { should contain_class('sudoadmns') }
  end
end
