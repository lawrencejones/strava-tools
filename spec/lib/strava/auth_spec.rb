require 'strava/auth'

RSpec.describe(Strava::Auth) do
  before { stub_const("#{described_class}::TOKEN_FILE", token_file) }
  let(:token_file) { Dir::Tmpname.make_tmpname('/tmp/strava-token-', nil) }

  describe '.token' do
    context 'when in file' do
      before { File.write(token_file, '<token>') }

      it 'does not call oauth process' do
        expect(described_class).not_to receive(:token_from_oauth)
        described_class.token
      end
    end
  end
end
