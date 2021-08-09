require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'


module RubyEventStore
  class InMemoryRepository
    class SpecHelper
      def supports_concurrent_auto?
        true
      end

      def supports_concurrent_any?
        true
      end

      def supports_binary?
        true
      end

      def supports_upsert?
        true
      end

      def has_connection_pooling?
        false
      end

      def connection_pool_size
      end

      def cleanup_concurrency_test
      end

      def rescuable_concurrency_test_errors
        []
      end

      def supports_position_queries?
        true
      end
    end
  end

  RSpec.describe InMemoryRepository do
    mk_repository = ->{ InMemoryRepository.new }

    it_behaves_like :event_repository, mk_repository, ::RubyEventStore::InMemoryRepository::SpecHelper.new

    let(:repository)   { mk_repository.call }
    let(:stream)       { Stream.new(SecureRandom.uuid) }

    it 'does not confuse all with GLOBAL_STREAM' do
      repository.append_to_stream(
        [SRecord.new(event_id: "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a")],
        Stream.new('all'),
        ExpectedVersion.none
      )
      repository.append_to_stream(
        [SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef")],
        Stream.new('stream'),
        ExpectedVersion.none
      )

      expect(repository.read(Specification.new(SpecificationReader.new(repository, Mappers::NullMapper.new)).result))
        .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a a1b49edb-7636-416f-874a-88f94b859bef]))

      expect(repository.read(Specification.new(SpecificationReader.new(repository, Mappers::NullMapper.new)).stream('all').result))
        .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a]))
    end

    it 'does not allow same event twice in a stream - checks stream events before checking all events' do
      repository.append_to_stream(
        [SRecord.new(event_id: eid = "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a")],
        Stream.new('other'),
        ExpectedVersion.none
      )
      repository.append_to_stream(
        [SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef")],
        Stream.new('stream'),
        ExpectedVersion.none
      )
      expect(eid).not_to receive(:eql?)
      expect do
        repository.append_to_stream(
          [SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef")],
          Stream.new('stream'),
          ExpectedVersion.new(0)
        )
      end.to raise_error(RubyEventStore::EventDuplicatedInStream)
    end

    it 'global position starts at 0' do
      repository.append_to_stream(
        [SRecord.new(event_id: eid = "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a")],
        Stream.new('other'),
        ExpectedVersion.none
      )

      expect(repository.global_position(eid)).to eq(0)
    end

    it 'global position increments by 1' do
      repository.append_to_stream(
        [
          SRecord.new(event_id: eid1 = "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a"),
          SRecord.new(event_id: eid2 = "0b81c542-7fef-47a1-9d81-f45915d74e9b"),
        ],
        Stream.new('other'),
        ExpectedVersion.none
      )

      expect(repository.global_position(eid2)).to eq(1)
    end

    it 'publishing with any position to stream with specific position raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.auto)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.any)
      end.to raise_error(RubyEventStore::InMemoryRepository::UnsupportedVersionAnyUsage)
    end

    it 'publishing with any position to stream with any position does not raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.any)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.any)
      end.not_to raise_error
    end

    it 'publishing with specific position to stream with any position raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.any)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.auto)
      end.to raise_error(RubyEventStore::InMemoryRepository::UnsupportedVersionAnyUsage)
    end

    it 'linking with any position to stream with specific position raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.auto)
      repository.append_to_stream([
        event1 = SRecord.new
      ],  Stream.new('other'), ExpectedVersion.auto)

      expect do
        repository.link_to_stream([
          event1.event_id,
        ], Stream.new('stream'), ExpectedVersion.any)
      end.to raise_error(RubyEventStore::InMemoryRepository::UnsupportedVersionAnyUsage)
    end

    it 'linking with any position to stream with any position does not raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.any)
      repository.append_to_stream([
        event1 = SRecord.new
      ],  Stream.new('other'), ExpectedVersion.auto)

      expect do
        repository.link_to_stream([
          event1.event_id
        ], Stream.new('stream'), ExpectedVersion.any)
      end.not_to raise_error
    end

    it 'linking with specific position to stream with any position raise an error' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: true)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.any)
      repository.append_to_stream([
        event1 = SRecord.new
      ],  Stream.new('other'), ExpectedVersion.auto)

      expect do
        repository.link_to_stream([
          event1.event_id
        ], Stream.new('stream'), ExpectedVersion.auto)
      end.to raise_error(RubyEventStore::InMemoryRepository::UnsupportedVersionAnyUsage)
    end

    it 'message for UnsupportedVersionAnyUsage' do
      expect(InMemoryRepository::UnsupportedVersionAnyUsage.new.message).to eq(
      <<~EOS
      Mixing expected version :any and specific position (or :auto) is unsupported.

      Read more about expected versions here:
      https://railseventstore.org/docs/v2/expected_version/
      EOS
      )
    end

    # This test only documents the 2.x behavior
    it 'publishing with any position to stream with specific position' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: false)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.auto)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.any)
      end.not_to raise_error
    end

    # This test only documents the 2.x behavior
    it 'publishing with specific position to stream with any position' do
      repository = InMemoryRepository.new(ensure_supported_any_usage: false)
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.any)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.auto)
      end.not_to raise_error
    end

    it 'stream position verification is turned off by default' do
      repository.append_to_stream([
        event0 = SRecord.new,
      ], Stream.new('stream'), ExpectedVersion.auto)

      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], Stream.new('stream'), ExpectedVersion.any)
      end.not_to raise_error
    end
  end
end
