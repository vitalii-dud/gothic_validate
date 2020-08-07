require_relative '../../lib/validator'

RSpec.describe Validator do
  subject { SampleClass.new(options) }

  before do
    class SampleClass
      include Validator

      attr_reader :validate_presence, :validate_absence, :validate_format, :validate_type

      validate :validate_presence, presence: true
      validate :validate_absence, presence: false
      validate :validate_format, format: /\d+/
      validate :validate_type, type: Array

      def initialize(**params)
        @validate_presence = params[:presence]
        @validate_absence = params[:absence]
        @validate_format = params[:format]
        @validate_type = params[:type]
      end
    end
  end

  context 'happy path' do
    let(:options) do
      {
        presence: true,
        format: '132123',
        type: []
      }
    end

    describe '#valid?' do
      it 'returns true' do
        expect(subject.valid?).to eq(true)
      end
    end

    describe '#validate!' do
      it 'returns true' do
        expect(subject.validate!).to eq(true)
      end
    end
  end

  context 'with non-valid attributes' do
    let(:options) do
      {
        absence: 'Here you go',
        format: 'RSpec',
        type: {}
      }
    end

    describe '#valid?' do
      it 'returns false' do
        expect(subject.valid?).to eq(false)
      end
    end

    describe '#validate!' do
      it 'returns array of error messages' do
        expect(subject.validate!).to match(
          {
            validate_presence: ['validate_presence should be present!'],
            validate_absence: ['validate_absence should not be present!'],
            validate_format: ['validate_format has invalid format!'],
            validate_type: ['validate_type should be an instance of Array!']
          }
        )
      end
    end
  end
end