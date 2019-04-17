require 'spec_helper'
require 'openssl'

module RubyEventStore
  module Mappers
    TicketTransferred = Class.new(RubyEventStore::Event) do
      def self.encryption_schema
        {
          sender: {
            name:  ->(data) { data.dig(:sender, :user_id) },
            email: ->(data) { data.dig(:sender, :user_id) },
          },
          recipient: {
            name:  ->(data) { data.dig(:recipient, :user_id) },
            email: ->(data) { data.dig(:recipient, :user_id) },
          }
        }
      end
    end

    TicketCancelled = Class.new(RubyEventStore::Event)

    TicketHolderEmailProvided = Class.new(RubyEventStore::Event) do
      def self.encryption_schema
        {
          email: ->(data) do
            data.fetch(:user_id)
          end
        }
      end
    end

    RSpec.describe EncryptionMapper do
      let(:key_repository) { InMemoryEncryptionKeyRepository.new }
      let(:serializer)     { YAML }
      let(:mapper)         { EncryptionMapper.new(key_repository, serializer: serializer) }
      let(:sender_id)      { SecureRandom.uuid }
      let(:recipient_id)   { SecureRandom.uuid }
      let(:event_id)       { SecureRandom.uuid }
      let(:ticket_id)      { SecureRandom.uuid }
      let(:correlation_id) { SecureRandom.uuid }
      let(:sender_email)   { 'alice@universe' }
      let(:recipient) do
        {
          user_id: recipient_id,
          name: 'Bob',
          email: 'bob@universe',
        }
      end
      let(:sender) do
        {
          user_id: sender_id,
          name: 'Alice',
          email: sender_email
        }
      end
      let(:data) do
        {
          ticket_id: ticket_id,
          sender: sender,
          recipient: recipient
        }
      end
      let(:metadata) do
        {
          correlation_id: correlation_id
        }
      end

      let(:ticket_transferred) do
        TicketTransferred.new(
          event_id: event_id,
          data: data,
          metadata: metadata
        )
      end

      let(:ticket_cancelled) do
        TicketCancelled.new(
          event_id: event_id,
          data: {
            ticket_id: ticket_id,
          },
          metadata: metadata
        )
      end

      def encrypt(e)
        mapper.event_to_serialized_record(e)
      end

      def decrypt(r)
        mapper.serialized_record_to_event(r)
      end

      specify 'decrypts encrypted fields in presence of encryption keys' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        event = decrypt(encrypt(ticket_transferred))

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          sender: sender,
          recipient: recipient
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'obfuscates data for missing keys on decryption' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        record = encrypt(ticket_transferred)
        key_repository.forget(sender_id.dup)
        event  = decrypt(record)

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          sender: {
            user_id: sender_id,
            name: ForgottenData::FORGOTTEN_DATA,
            email: ForgottenData::FORGOTTEN_DATA,
          },
          recipient: recipient
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'obfuscates data for incorrect keys on decryption' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        record = encrypt(ticket_transferred)
        key_repository.forget(sender_id)
        key_repository.create(sender_id)
        event  = decrypt(record)

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          sender: {
            user_id: sender_id,
            name: ForgottenData::FORGOTTEN_DATA,
            email: ForgottenData::FORGOTTEN_DATA,
          },
          recipient: recipient
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'no-op for events without encryption schema' do
        event = decrypt(encrypt(ticket_cancelled))

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'no encryption metadata without encryption schema' do
        record = encrypt(ticket_cancelled)
        expect(serializer.load(record.metadata)).to eq(metadata)
      end

      specify 'raises error on encryption with missing encryption key' do
        expect do
          encrypt(ticket_transferred)
        end.to raise_error(MissingEncryptionKey, "Could not find encryption key for '#{sender_id}'")
      end

      specify 'does not modify original event' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        event = ticket_transferred
        encrypt(event)

        expect(event.data.dig(:sender, :name)).to eq('Alice')
        expect(event.data.dig(:sender, :email)).to eq(sender_email)
        expect(event.data.dig(:recipient, :name)).to eq('Bob')
        expect(event.data.dig(:recipient, :email)).to eq('bob@universe')
        expect(event.metadata).not_to have_key(:encryption)
      end

      specify 'does not modify original record' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        record   = encrypt(ticket_transferred)
        data     = serializer.load(record.data)
        metadata = serializer.load(record.metadata)
        decrypt(record)

        expect(serializer.load(record.data)).to     eq(data)
        expect(serializer.load(record.metadata)).to eq(metadata)
      end

      specify 'two cryptograms of the same input and key are not alike' do
        key_repository.create(sender_id)

        record = encrypt(
          TicketTransferred.new(
            event_id: event_id,
            data: {
              ticket_id: ticket_id,
              sender: sender,
              recipient: sender
            },
            metadata: metadata
          )
        )
        data = serializer.load(record.data)

        expect(data.dig(:sender, :name)).not_to  eq(data.dig(:recipient, :name))
        expect(data.dig(:sender, :email)).not_to eq(data.dig(:recipient, :email))
      end

      specify 'handles non-nested encryption schema' do
        key_repository.create(sender_id)

        event = 
          decrypt(
            encrypt(
              TicketHolderEmailProvided.new(
                event_id: event_id,
                data: {
                  ticket_id: ticket_id,
                  user_id: sender_id,
                  email: sender_email
                },
                metadata: metadata
              )
            )
          )

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          user_id: sender_id,
          email: sender_email
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'handles non-string values' do
        key_repository.create(sender_id)

        event =
          decrypt(
            encrypt(
              TicketHolderEmailProvided.new(
                event_id: event_id,
                data: {
                  ticket_id: ticket_id,
                  user_id: sender_id,
                  email: [sender_email]
                },
                metadata: metadata
              )
            )
          )

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          user_id: sender_id,
          email: [sender_email]
        })
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'no-op for nil value' do
        key_repository.create(sender_id)

        record =
          encrypt(
            TicketHolderEmailProvided.new(
              event_id: event_id,
              data: {
                ticket_id: ticket_id,
                user_id: sender_id,
                email: nil
              },
              metadata: metadata
            )
          )
        event = decrypt(record)

        expect(event.event_id).to eq(event_id)
        expect(event.data).to eq({
          ticket_id: ticket_id,
          user_id: sender_id,
          email: nil
        })
        expect(serializer.load(record.data)).to eq(event.data)
        expect(event.metadata.to_h).to eq(metadata)
      end

      specify 'defaults' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)
        record =
          EncryptionMapper
            .new(key_repository)
            .event_to_serialized_record(ticket_transferred)
        event =
          EncryptionMapper
            .new(key_repository)
            .serialized_record_to_event(record)

        expect(event).to  eq(ticket_transferred)
      end

      specify 'handles decryption after changing cipher' do
        key_repository.create(sender_id)
        key_repository.create(recipient_id)

        record = encrypt(ticket_transferred)

        with_default_cipher('aes-128-gcm') do
          event = decrypt(record)

          expect(event.event_id).to eq(event_id)
          expect(event.data).to eq({
            ticket_id: ticket_id,
            sender: sender,
            recipient: recipient
          })
          expect(event.metadata.to_h).to eq(metadata)
        end
      end

      specify 'decrypted message is UTF-8 encoded' do
        key = key_repository.create('dummy')
        iv  = key.random_iv
        source_message    = 'zażółć gęślą jaźń'
        decrypted_message = key.decrypt(key.encrypt(source_message, iv), iv)

        expect(decrypted_message).to eq(source_message)
        expect(decrypted_message.encoding).to eq(Encoding::UTF_8)
      end

      specify 'allow use of non-authenticated cipher' do
        with_default_cipher('aes-256-cbc') do
          key_repository.create(sender_id)
          key_repository.create(recipient_id)

          event = decrypt(encrypt(ticket_transferred))

          expect(event.event_id).to eq(event_id)
          expect(event.data).to eq({
            ticket_id: ticket_id,
            sender: sender,
            recipient: recipient
          })
          expect(event.metadata.to_h).to eq(metadata)
        end
      end

      def with_default_cipher(cipher, &block)
        cipher_ = InMemoryEncryptionKeyRepository::DEFAULT_CIPHER
        InMemoryEncryptionKeyRepository.send(:remove_const, :DEFAULT_CIPHER)
        InMemoryEncryptionKeyRepository.const_set(:DEFAULT_CIPHER, cipher)
        block.call
      ensure
        InMemoryEncryptionKeyRepository.send(:remove_const, :DEFAULT_CIPHER)
        InMemoryEncryptionKeyRepository.const_set(:DEFAULT_CIPHER, cipher_)
      end
    end

    RSpec.describe ForgottenData do
      specify 'compares with string' do
        expect(ForgottenData.new).to                eq(ForgottenData::FORGOTTEN_DATA)
        expect(ForgottenData.new('bazinga')).to     eq('bazinga')
        expect(ForgottenData.new('bazinga')).not_to eq(ForgottenData::FORGOTTEN_DATA)
      end

      specify "prints as string" do
        expect{ print(ForgottenData.new) }.to            output(ForgottenData::FORGOTTEN_DATA).to_stdout
        expect{ print(ForgottenData.new('bazinga')) }.to output('bazinga').to_stdout
      end

      specify 'behaves like null object' do
        data = ForgottenData.new
        expect(data.foo.bar[:baz]).to eq(data)
      end
    end
  end
end
