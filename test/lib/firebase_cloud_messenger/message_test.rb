require 'test_helper'

class FirebaseCloudMessenger::MessageTest < MiniTest::Spec
  describe "#new" do
    it "sets properties based on the hash arg" do
      msg = FirebaseCloudMessenger::Message.new(name: "name",
                                                data: "data",
                                                notification: "notification",
                                                android: "android",
                                                webpush: "webpush",
                                                apns: "apns",
                                                fcm_options: "fcm_options",
                                                token: "token",
                                                topic: "topic",
                                                condition: "condition")

      %i(name data notification android webpush apns fcm_options token topic condition).each do |field|
        assert_equal field.to_s, msg.send(field)
      end
    end

    it "throws an ArgumentError if key is not in fields" do
      assert_raises ArgumentError do
        FirebaseCloudMessenger::Message.new(foo: "foo")
      end
    end
  end

  describe "#to_h" do
    describe "with objects all the way down" do
      it "returns a hash version of the object" do
        data = { some: "data" }
        notification = FirebaseCloudMessenger::Notification.new(title: "title")

        android_notification = FirebaseCloudMessenger::Android::Notification.new(title: "title")
        android_config = FirebaseCloudMessenger::Android::Config.new(notification: android_notification)

        webpush_notification = FirebaseCloudMessenger::Webpush::Notification.new(title: "title")
        webpush_config = FirebaseCloudMessenger::Webpush::Config.new(notification: webpush_notification)

        apns_alert = FirebaseCloudMessenger::Apns::Alert.new(title: "title")
        aps_dictionary = FirebaseCloudMessenger::Apns::ApsDictionary.new(alert: apns_alert, badge: 2)
        apns_payload = FirebaseCloudMessenger::Apns::Payload.new(aps: aps_dictionary)
        apns_config = FirebaseCloudMessenger::Apns::Config.new(payload: apns_payload)

        fcm_options = FirebaseCloudMessenger::FcmOptions.new(analytics_label: "analytics_label")

        msg = FirebaseCloudMessenger::Message.new(name: "name",
                                                  data: data,
                                                  notification: notification,
                                                  android: android_config,
                                                  webpush: webpush_config,
                                                  apns: apns_config,
                                                  fcm_options: fcm_options,
                                                  token: "token",
                                                  topic: "topic",
                                                  condition: "condition")

        expected = {
          name: "name",
          data: { some: "data" },
          notification: { title: "title" },
          android: { notification: { title: "title" } },
          webpush: { notification: { title: "title" } },
          apns: { payload: { aps: { alert: { title: "title" }, badge: 2 } } },
          token: "token",
          topic: "topic",
          condition: "condition",
          fcm_options: { analytics_label: "analytics_label" }
        }

        assert_equal expected, msg.to_h
      end
    end

    describe "with hashes instead of objects" do
      it "returns a hash version of the object" do
        args = {
          name: "name",
          data: { some: "data" },
          notification: { title: "title" },
          android: { notification: { title: "title" } },
          webpush: { notification: { title: "title" } },
          apns: { payload: { alert: { title: "title" }, badge: 2 } },
          fcm_options: { analytics_label: "analytics_label" },
          token: "token",
          topic: "topic",
          condition: "condition"
        }

        msg = FirebaseCloudMessenger::Message.new(args.dup)

        assert_equal args, msg.to_h
      end
    end
  end

  describe "#valid?" do
    describe "against_api: true" do
      it "returns true if there are no errors" do
        message = FirebaseCloudMessenger::Message.new(name: "name")

        FirebaseCloudMessenger.expects(:send).with(message: message, validate_only: true, conn: nil).returns(true)

        assert message.valid?(against_api: true)
      end

      it "adds errors and returns false there are any errors" do
        message = FirebaseCloudMessenger::Message.new(name: "name")

        error = FirebaseCloudMessenger::BadRequest.new
        error.stubs(details: ["bad", "data"])
        FirebaseCloudMessenger.expects(:send).with(message: message, validate_only: true, conn: nil).raises(error)

        message_valid = message.valid?(against_api: true)

        assert_equal ["bad", "data"], message.errors
        refute message_valid
      end
    end

    describe "against_api: false" do
      it "returns false and sets errors if the message doesn't validate against the schema" do
        message = FirebaseCloudMessenger::Message.new(name: "name")

        refute message.valid?
        refute_empty message.errors
      end

      it "returns true if the message validates against the schema" do
        message = FirebaseCloudMessenger::Message.new(data: { "some" => "data" }, token: "token", notification: { title: "title" })

        assert message.valid?
      end
    end
  end
end
